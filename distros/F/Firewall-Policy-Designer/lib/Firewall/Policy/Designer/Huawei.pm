package Firewall::Policy::Designer::Huawei;

#------------------------------------------------------------------------------
# 引用基础模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Utils::Set;
use Firewall::Policy::Searcher::Report::FwInfo;

#------------------------------------------------------------------------------
# 继承 Firewall::Policy::Designer::Role 通用属性
#------------------------------------------------------------------------------
# with 'Firewall::Policy::Designer::Role';

#------------------------------------------------------------------------------
# Firewall::Policy::Designer::Huawei 通用属性
#------------------------------------------------------------------------------
has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,
);

has searcherReportFwInfo => (
  is       => 'ro',
  isa      => 'Firewall::Policy::Searcher::Report::FwInfo',
  required => 1,
);

has commandText => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

#------------------------------------------------------------------------------
# addToCommandText 向 commandText 属性推送命令行
#------------------------------------------------------------------------------
sub addToCommandText {
  my ( $self, @commands ) = @_;
  push @{$self->{commandText}}, @commands;
}

#------------------------------------------------------------------------------
# design 策略设计函数入口，入参为防火墙策略报告 -> searcherReportFwInfo
#------------------------------------------------------------------------------
sub design {
  my $self = shift;

  # 初始化防火墙策略报告下 type action 属性
  my $type   = $self->{searcherReportFwInfo}{type}   if exists $self->{searcherReportFwInfo}{type};
  my $action = $self->{searcherReportFwInfo}{action} if exists $self->{searcherReportFwInfo}{action};


  # 情况1：当类型为 new，则新建策略
  if ( $type eq "new" ) {
    $self->createRule();
  }

  # 情况2：当类型为 modify，则修改策略
  elsif ( $type eq "modify" ) {
    $self->createRule();
  }

  # 情况3：当类型为 ignore，还需要检查是否存在 NAT 策略
  elsif ( $type eq "ignore" ) {
    my $param = $action->{new} if defined $action;
    for my $natDirection ( keys %{$param} ) {
      if ( $natDirection eq "natSrc" || $natDirection eq "natDst" ) {
        $self->checkAndCreateNat( $param->{$natDirection}, $type );
      }
    }
  }

  # 其他情况：抛出异常，定位排除
  else {
    warn "ERROR: searcherReportFwInfo->type(" . $self->{"searcherReportFwInfo"}{"type"} . ") must be 'new' or 'modify'";
    confess $@;
  }

  # 拼接数组为字符串并返回
  return join( "\n", @{$self->{"commandText"}} );
} ## end sub design

#------------------------------------------------------------------------------
# design 策略设计函数入口，入参为防火墙策略报告 -> searcherReportFwInfo
#------------------------------------------------------------------------------
sub createRule {
  my $self = shift;

  # 初始化 commands
  my @commands;

  # 判断是否需要 nat
  my $action = $self->searcherReportFwInfo->action->{new};
  my $natSrc = $action->{natSrc} if defined $action->{natSrc};
  my $natDst = $action->{natDst} if defined $action->{natDst};

  # 确认是否需要新增 nat
  my $natInfo;
  if ( defined $natSrc ) {
    foreach ( values %{$natSrc} ) {
      $natInfo->{natSrc} = $_;
      $self->checkAndCreateNat($natInfo);
    }
  }
  if ( defined $natDst ) {
    foreach ( values %{$natDst} ) {
      $natInfo->{natDst} = $_;
      $self->checkAndCreateNat($natInfo);
    }
  }

  # 初始化访问控制 5 元组 -> 源目地址、区域、服务端口
  my $fromZone = $self->{searcherReportFwInfo}{fromZone};
  my $toZone   = $self->{searcherReportFwInfo}{toZone};
  my $schedule = $self->{searcherReportFwInfo}->{schedule};
  my @srcs     = keys %{$self->{searcherReportFwInfo}{action}{new}{src}};
  my @dsts     = keys %{$self->{searcherReportFwInfo}{action}{new}{dst}};
  my @srvs     = keys %{$self->{searcherReportFwInfo}{action}{new}{srv}};
  my $sch      = $self->createSchedule($schedule) if $schedule->{enddate} ne 'always';

  # 动态启用地址组
  my $randNum  = $$ || sprintf( '%05d', int( rand(99999) ) );
  my $ruleName = 'policy_' . Firewall::Utils::Date->getFormatedDate('yyyymmdd_hhmiss') . "_$randNum";
  push @commands, "security-policy";
  push @commands, "rule name $ruleName";
  push @commands, "source-zone $fromZone";
  push @commands, "destination-zone $toZone";

  # 优先使用动态地址组
  my ( $srcGroup, $dstGroup );

  # 源地址成员大于3
  if ( @srcs > 3 ) {
    $srcGroup = $self->createAddrGroup( \@srcs );
    push @commands, "source-address address-set $srcGroup";
  }
  else {
    my @srcAddrs = $self->createAddress( \@srcs, "src" );
    push @commands, @srcAddrs;
  }

  # 目的地址成员大于3
  if ( @dsts > 3 ) {
    $dstGroup = $self->createAddrGroup( \@dsts );
    push @commands, "destination-address address-set $dstGroup";
  }
  else {
    my @dstAddrs = $self->createAddress( \@dsts, "dst" );
    push @commands, @dstAddrs;
  }

  # 遍历服务端口成员
  my @srvsobjs;
  for my $srv (@srvs) {
    my $srvName = $self->createService($srv);
    push @srvsobjs, $srvName;
  }

  # 推送访问控制服务端口命令行
  for my $srvobj (@srvsobjs) {
    push @commands, "service $srvobj";
  }

  # 推送访问控制时间策略
  if ( defined $sch ) {
    push @commands, "time-range $sch";
  }

  # 推送访问控制动作
  push @commands, "action permit";
  push @commands, "quit";

  # 返回计算结果
  $self->addToCommandText(@commands);
} ## end sub createRule

#------------------------------------------------------------------------------
# createAddress 创建地址对象
#------------------------------------------------------------------------------
sub createAddress {
  my ( $self, $addrMap, $srcOrDst ) = @_;

  # 初始化 cmdStr
  my ( $cmdStr, @commands );
  my $direction = ( $srcOrDst eq "src" ) ? "source-address" : ( $srcOrDst eq "dst" ) ? "destination-address" : undef;

  # 遍历 addrMap
  foreach my $addr ( @{$addrMap} ) {

    # 初始化 ip mask
    my ( $ip, $mask ) = split( '/', $addr );

    # 情况1：单个地址或子网
    if ( defined $mask and $mask == 0 ) {
      $cmdStr = "$direction any";
      push @commands, $cmdStr;
    }
    elsif ( defined $mask and $mask ) {
      $mask   = Firewall::Utils::Ip->changeMaskToIpForm($mask);
      $cmdStr = "$direction $ip mask $mask" if defined $direction;
      push @commands, $cmdStr;
    }

    # 情况2：连续地址段
    else {
      if ( $ip
        =~ /^(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?)-(2[0-4]\d|25[0-5]|1?\d\d?)$/
        )
      {
        my ( $ipMin, $ipMax ) = split( "-", $ip );
        $ipMax  = $1 . $2 . $3 . $5;
        $cmdStr = "$direction range $ipMin $ipMax" if defined $direction;
        push @commands, $cmdStr;
      }
    }
  } ## end foreach my $addr ( @{$addrMap...})

  # 返回计算结果
  return @commands;
} ## end sub createAddress

#------------------------------------------------------------------------------
# createService 新增服务端口命令行配置命令行
#------------------------------------------------------------------------------
sub createService {
  my ( $self, $srv ) = @_;

  # 初始化 serviceName dstPort commands
  my ( $serviceName, $dstPort, @commands );

  # 拆解 protocol port
  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;

  # 仅支持 TCP/UDP 需要指定端口
  return if $protocol ne 'tcp' and $protocol ne 'udp';

  # 情况1：连续端口
  if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
    $serviceName = $protocol . "_" . $+{portMin} . "-" . $+{portMax};
    $dstPort     = $+{portMin} . " to " . $+{portMax};
  }

  # 情况2：单一端口
  elsif ( $port =~ /^\d+$/o ) {
    $serviceName = $protocol . "_" . $port;
    $dstPort     = $port;
  }

  # 未匹配的端口信息
  else {
    confess "ERROR: $port is not a port";
  }

  # 推送配置
  push @commands, "ip service-set $serviceName type object";
  push @commands, "service protocol source-port 0 to 65535 destination-port $dstPort";
  push @commands, "quit";

  # 返回计算结果
  $self->addToCommandText(@commands);
  return $serviceName;
} ## end sub createService

#------------------------------------------------------------------------------
# createSchedule 新增时间策略命令行
#------------------------------------------------------------------------------
sub createSchedule {
  my ( $self, $schedule ) = @_;

  # 初始化 commands
  my @commands;

  # 获取起止时间属性
  my $startDate = $schedule->{"startdate"};
  my $endDate   = $schedule->{"enddate"};

  # 如果未定义起止时间则跳过
  return if not defined $startDate;

  # 分割时间
  my ( $syear, $smon, $sday, $shh, $smm ) = split( '[ :-]', $startDate );
  my ( $year,  $mon,  $day,  $hh,  $mm )  = split( '[ :-]', $endDate );
  my $schName = sch_ $year - $mon - $day;

  # 推送配置
  push @commands, "time-range $schName";
  push @commands, "absolute-range $shh:$smm:00 $syear/$smon/$sday end $hh:$mm:00 $year/$mon/$day";
  push @commands, "quit";

  # 返回计算属性
  $self->addToCommandText(@commands);
  return $schName;
} ## end sub createSchedule

#------------------------------------------------------------------------------
# createAddrGroup 新增地址组命令行
#------------------------------------------------------------------------------
sub createAddrGroup {
  my ( $self, $addrMap ) = @_;

  # 初始化 addrs commands
  my ( @addrs, @commands );

  # 初始化防火墙解析对象
  my $parser = $self->{"searcherReportFwInfo"}{"parser"};

  # 创建随机地址组
  my $groupId   = sprintf( '%d', 100 + int( rand(10000) ) );
  my $groupName = "addrSet_" . $groupId;

  # 生成唯一的地址组
  while ( defined $parser->getAddress($groupName) ) {
    $groupName = "addrSet_" . sprintf( '%d', 100 + int( rand(10000) ) );
  }

  push @commands, "ip address-set $groupName type object";

  # 转换 addrMap 为集合对象
  my $addrSet = Firewall::Utils::Set->new();
  for my $addr ( @{$addrMap} ) {
    my ( $ip, $mask ) = split( '/', $addr );
    $addrSet->mergeToSet( Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask ) );
  }

  # 遍历区间集合，重组 $addrs (有可能连续的地址可缩写)
  for ( my $i = 0; $i < $addrSet->length; $i++ ) {
    my $min = $addrSet->{"mins"}[$i];
    my $max = $addrSet->{"maxs"}[$i];
    push @addrs, Firewall::Utils::Ip->getIpMaskFromRange( $min, $max );
  }

  # 遍历 addrs
  for my $addr (@addrs) {

    # 情况1：匹配连续地址段
    if ( $addr =~ /\-/ ) {
      my ( $ipMin, $ipMax ) = split( '-', $addr );
      push @commands, "address range $ipMin $ipMax";
    }

    # 情况2：单个地址或子网
    else {
      my ( $ip, $mask ) = split( '/', $addr );
      push @commands, "address $ip mask $mask";
    }
  }

  # 推送代码块结束命令行
  push @commands, "quit";
  $self->addToCommandText(@commands);

  # 返回计算结果
  return $groupName;
} ## end sub createAddrGroup

#------------------------------------------------------------------------------
# isNewVer 检测是否为新版本防火墙
#------------------------------------------------------------------------------
sub isNewVer {
  my $self = shift;

  # 获取防火墙版本信息
  my $version = $self->{"searcherReportFwInfo"}{"parser"}{"version"};

  # 判断防火墙版本
  if ( defined $version ) {
    if ( $version =~ /V(?<mainVer>\d+)R\d+/i ) {
      my $mainVer = $+{"mainVer"};
      return ( $mainVer >= 500 ) ? 1 : 0;
    }
  }
}

#------------------------------------------------------------------------------
# createPool 新增 natPool
#------------------------------------------------------------------------------
sub createPool {
  my ( $self, $natIp, $type ) = @_;

  # 初始化 commands
  my @commands;

  #  初始化 poolName
  my $ipRange
    = qr/(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?)-(2[0-4]\d|25[0-5]|1?\d\d?)/;
  my $ipAndMask
    = qr/(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?\.)(2[0-4]\d|25[0-5]|1?\d\d?)/;
  my $poolName = "natPool_$natIp";

  # 情况1：源地址动态NAT
  if ( $type eq 'natSrc' ) {
    push @commands, "nat address-group $poolName";
    push @commands, "mode pat";
  }

  # 情况2：目的地址动态NAT
  elsif ( $type eq 'natDst' ) {
    push @commands, "destination-nat address-group $poolName";
  }

  # 情况1：natIp匹配连续地址段
  if ( $natIp =~ $ipRange ) {
    my ( $ipMin, $ipMax ) = split( '-', $natIp );
    $ipMax = $1 . $2 . $3 . $5;
    push @commands, "section $ipMin $ipMax";
  }

  # 情况2：natIp匹配单个地址或子网
  elsif ( $natIp =~ $ipAndMask ) {
    my ( $ip, $mask ) = split( '/', $natIp );
    $mask = 32 if not defined $mask;
    my ( $min, $max ) = Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask );
    my $ipMin = Firewall::Utils::Ip->changeIntToIp($min);
    my $ipMax = Firewall::Utils::Ip->changeIntToIp($max);
    push @commands, "section $ipMin $ipMax";
  }

  # 推送代码块结束命令行
  push @commands, "quit";
  $self->addToCommandText(@commands);

  # 返回计算结果
  return $poolName;
} ## end sub createPool

#------------------------------------------------------------------------------
# createPool 新增 natPool
#------------------------------------------------------------------------------
sub newCheckAndCreateNat {

}

sub checkAndCreateNat {
  my ( $self, $param ) = @_;

  return unless $self->isNewVer();
  my @commands;
  my $ippat = '\d+\.\d+\.\d+\.\d+';
  push @commands, "nat-policy";
  my $randNum  = sprintf( '%05d', int( rand(99999) ) );
  my $timeNow  = Firewall::Utils::Date->getFormatedDate('yyyymmdd_hhmiss') . "_$randNum";
  my $ruleName = "policy_nat_$timeNow";
  my $fromZone = $self->{"searcherReportFwInfo"}{"fromZone"};
  my $toZone   = $self->{"searcherReportFwInfo"}{"toZone"};
  my $srvMap   = $self->{"searcherReportFwInfo"}{"srvMap"};
  push @commands, "rule name $ruleName";
  push @commands, "source-zone $fromZone";
  push @commands, "destination-zone $toZone";

  for my $type ( keys %{$param} ) {
    my $natIp   = $param->{$type}{natInfo}{natIp};
    my $natType = $param->{$type}{natInfo}{natType};
    my $realIp  = $param->{$type}->{realIp};
    my ( $ip, $mask ) = split( '/', $realIp );
    $mask = 32 if not defined $mask;
    my ( $mip, $mmask ) = split( '/', $natIp );
    $mmask = 32 if not defined $mmask;
    if ( $type eq 'natSrc' ) {

      if ( not defined $natIp ) {
        my ( $ip, $mask ) = split( '/', $realIp );
        $mask = 32 if not defined $mask;
        push @commands, "source-address $ip $mask";
        push @commands, "action source-nat easy-ip";
        push @commands, "quit";
      }
      else {
        my ( $ip, $mask ) = split( '/', $realIp );
        $mask = 32 if not defined $mask;
        my $poolName = $self->createPool( $natIp, $type );
        push @commands, "source-address $ip $mask";
        push @commands, "action source-nat address-group $poolName";
        push @commands, "quit";
      }
    }
    elsif ( $type eq 'natDst' ) {
      if ( $natIp =~ /$ippat\/\d+/ ) {
        my ( $ip, $mask ) = split( '/', $natIp );
        push @commands, "destination-address $ip $mask";
      }
      elsif ( $natIp =~ /$ippat-$ippat/ ) {
        my ( $ipMin, $ipMax ) = split( '-', $natIp );
        push @commands, "destination-address range $ipMin $ipMax";

      }
      my $natPort = "";
      for my $srv ( keys %{$srvMap} ) {
        if ( defined $srvMap->{$srv}{natPort} ) {
          my ( $proto, $port ) = split( '/', $srv );
          push @commands, "service protocol $proto destination-port $port";
          $natPort = $srvMap->{$srv}{natPort};
        }
      }
      my $poolName = $self->createPool( $natIp, $type );
      push @commands, "action destination-nat address-group $poolName $natPort";
      push @commands, "quit";

    } ## end elsif ( $type eq 'natDst')

  } ## end for my $type ( keys %{$param...})
  $self->addToCommandText(@commands);
} ## end sub checkAndCreateNat

sub createDynamicNat {

}

sub createStaticNat {

}

sub getPoolName {
  my ( $self, $toZone, $natIp ) = @_;

  # 初始化 poolName
  my $poolName;

  # 初始化 parser
  my $parser = $self->{"searcherReportFwInfo"}{"parser"};

  # 转换 natIp 为集合对象
  my ( $ip, $mask ) = split( '/', $natIp );
  $mask = 32 if not defined $mask;
  my $natIpSet = Firewall::Utils::Ip->getRangeFromIpMask( $ip, $mask );

  # 遍历已有 natPool
  for my $natPool ( values %{$parser->{"elements"}{"natPool"}} ) {
    if ( $natPool->{"zone"} eq $toZone and $natPool->{"poolRange"}->isContain($natIpSet) ) {
      $poolName = $natPool->{"poolName"};

      # 找到即停
      return $poolName;
    }
  }
} ## end sub getPoolName

__PACKAGE__->meta->make_immutable;
1;
