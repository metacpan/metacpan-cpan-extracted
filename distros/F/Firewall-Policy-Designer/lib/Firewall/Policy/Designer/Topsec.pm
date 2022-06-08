package Firewall::Policy::Designer::Topsec;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
no warnings 'uninitialized';
use List::Util qw( uniq );
use Mojo::Util qw(dumper);

#------------------------------------------------------------------------------
# getAnalyzerReport 获取防火墙策略源目地址、服务端口分析报告
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Policy::Searcher::Topsec;
use Firewall::Policy::Searcher::Report::FwInfo;

#------------------------------------------------------------------------------
# Firewall::Policy::Designer::Topsec 通用属性
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
# addToCommandText 设置 commandText 属性，入参为标量
#------------------------------------------------------------------------------
sub addToCommandText {
  my ( $self, $commands ) = @_;
  push @{$self->{"commandText"}}, $commands;
}

#------------------------------------------------------------------------------
# design 策略设计函数入口，入参为防火墙策略报告 -> searcherReportFwInfo
#------------------------------------------------------------------------------
sub design {
  my $self = shift;

  # 提取防火墙策略报告下 type 属性
  my $type   = $self->{"searcherReportFwInfo"}{"type"};
  my $action = $self->{"searcherReportFwInfo"}{"action"};

  # 情况1：当类型为 new，则新建策略
  if ( $type eq 'new' ) {
    $self->createRule();
  }

  # 情况2：当类型为 modify，则修改策略
  elsif ( $type eq 'modify' ) {
    $self->modifyRule();
  }

  # 情况3：当类型为 ignore，还需要检查是否存在 NAT 策略
  elsif ( $type eq 'ignore' ) {
    my $param = $action->{"new"} if defined $action;
    for my $natDirection ( keys %{$param} ) {
      if ( $natDirection eq 'natSrc' || $natDirection eq 'natDst' ) {
        $self->createNat( $param->{$natDirection}, $type );
      }
    }
  }

  # 其他情况：抛出异常，定位排除
  else {
    confess "ERROR: searcherReportFwInfo->type("
      . $self->{"searcherReportFwInfo"}{"type"}
      . ") must be 'new' or 'modify'";
  }

  # 拼接数组为字符串并返回
  return join( "\n", uniq @{$self->{"commandText"}} );
} ## end sub design

#------------------------------------------------------------------------------
# createRule 新增策略
#------------------------------------------------------------------------------
sub createRule {
  my $self = shift;

  # 新增策略其 action 为 new
  my $create = $self->{"searcherReportFwInfo"}{"action"}{"new"};

  # 获取源目安全区并拼接
  my ( $fromZone, $toZone )
    = ( $self->{"searcherReportFwInfo"}{"fromZone"}, $self->{"searcherReportFwInfo"}{"toZone"} );

  #my $zoneStr = ( $fromZone and $toZone ) ? "srcarea '$fromZone ' dstarea '$toZone '" : '';
  my $zoneStr = '';

  # 根据策略查询结果进行命令拼接
  my ( $srcStr, $dstStr, $srvStr );
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat($create);

  # 遍历 addrOrSrvMap
  for my $addrOrSrv ( keys %{$nameMap} ) {

    # 情况1：当类型为 src，依次取出判断
    if ( $addrOrSrv eq 'src' ) {

      # srcStr 前后需要使用 ''
      $srcStr = "src '";
      for my $host ( @{$nameMap->{$addrOrSrv}} ) {
        $srcStr .= $host . " ";
      }

      # srcStr 前后需要使用 ''
      $srcStr .= "'";
    }

    # 情况2：当类型为 dst，依次取出判断
    elsif ( $addrOrSrv eq 'dst' ) {

      # dstStr 前后需要使用 ''
      $dstStr = "dst '";
      for my $host ( @{$nameMap->{$addrOrSrv}} ) {
        $dstStr .= $host . " ";
      }

      # dstStr 前后需要使用 ''
      $dstStr .= "'";

    }

    # 情况3：当类型为 src，依次取出判断
    elsif ( $addrOrSrv eq 'srv' ) {

      # srvStr 前后需要使用 ''
      $srvStr = "service '";
      for my $srv ( @{$nameMap->{$addrOrSrv}} ) {
        $srvStr .= $srv . " ";
      }

      # srvStr 前后需要使用 ''
      $srvStr .= "'";
    }
  } ## end for my $addrOrSrv ( keys...)

  # 拼接成新增策略
  my $cmdStr = "firewall policy add action accept $zoneStr $srcStr $dstStr $srvStr";

  # 添加计算结果
  $self->addToCommandText($cmdStr);
} ## end sub createRule

#------------------------------------------------------------------------------
# modifyRule 策略修改
#------------------------------------------------------------------------------
sub modifyRule {
  my $self = shift;

  # 修改策略其 action 为 add 并获取其 policyId
  my $modify   = $self->{"searcherReportFwInfo"}{"action"}{"add"};
  my $policyId = $self->{"searcherReportFwInfo"}{"ruleObj"}{"policyId"};
  my $content  = $self->{"searcherReportFwInfo"}{"ruleObj"}{"content"};

  # 可能已开通访问控制但缺少 NAT 转换
  my $action = $self->{"searcherReportFwInfo"}{"action"}{"new"};
  if ( defined $action ) {
    for my $natDirection ( keys %{$action} ) {
      if ( $natDirection eq 'natDst' or $natDirection eq 'natSrc' ) {
        $self->createNat( $action->{$natDirection}, $natDirection );
      }
    }
  }

  # 遍历 addrOrSrvMap
  my ( $srcMem, $dstMem, $srvMem );
  my $nameMap = $self->checkAndCreateAddrOrSrvOrNat($modify);
  for my $addrOrSrv ( keys %{$nameMap} ) {

    # 情况1：源地址
    if ( $addrOrSrv eq 'src' ) {
      $content =~ /src\s+'(?<src>.+?)'/mi;
      my $srcStr = $+{"src"};
      for my $host ( @{$nameMap->{$addrOrSrv}} ) {
        $srcStr .= $host . " ";
      }
      $srcMem .= "src ' $srcStr' ";
    }

    # 情况2：目的地址
    elsif ( $addrOrSrv eq 'dst' ) {
      $content =~ /dst\s+'(?<dst>.+?)'/mi;
      my $dstStr = $+{"dst"};
      for my $host ( @{$nameMap->{$addrOrSrv}} ) {
        $dstStr .= $host . " ";
      }
      $dstMem .= "dst ' $dstStr' ";
    }

    # 情况3：服务端口
    elsif ( $addrOrSrv eq 'srv' ) {
      $content =~ /service\s+'(?<srv>.+?)'/mi;
      my $srvStr = $+{"srv"};
      for my $srv ( @{$nameMap->{$addrOrSrv}} ) {
        $srvStr .= $srv . " ";
      }
      $srvMem .= "service ' $srvStr' ";
    }
  } ## end for my $addrOrSrv ( keys...)
  my $cmdStr = "policy modify id $policyId $srcMem $dstMem $srvMem";
  $self->addToCommandText($cmdStr);
} ## end sub modifyRule

#------------------------------------------------------------------------------
# checkAndCreateAddrOrSrvOrNat 创建地址、服务端口或NAT
#------------------------------------------------------------------------------
sub checkAndCreateAddrOrSrvOrNat {
  my ( $self, $param ) = @_;

  # 初始化 nameMap 标量
  my $nameMap;

  # 遍历 param
  for my $type ( keys %{$param} ) {

    # 情况1： nat 转换
    if ( $type eq 'natDst' or $type eq 'natSrc' ) {
      $nameMap->{$type} = $self->createNat( $param->{$type}, $type );
    }

    # 情况2：addrOrSrv 配置
    elsif ( $type ne 'natDst' and $type ne 'natSrc' ) {
      for my $addrOrSrv ( keys %{$param->{$type}} ) {

        # 情况2.1：未定义则新增
        if ( not defined $param->{$type}{$addrOrSrv} ) {
          my $createAddrOrSrv = "create" . ( ucfirst $type );
          push @{$nameMap->{$type}}, $self->$createAddrOrSrv($addrOrSrv);
        }

        # 情况2.2：已定义则复用
        else {
          push @{$nameMap->{$type}}, $param->{$type}{$addrOrSrv}[0];
        }
      }
    }
  } ## end for my $type ( keys %{$param...})

  # 返回计算结果
  return $nameMap;
} ## end sub checkAndCreateAddrOrSrvOrNat

#------------------------------------------------------------------------------
# createNat 创建 NAT 函数入口，支持静态和动态 NAT
#------------------------------------------------------------------------------
sub createNat {
  my ( $self, $param, $type ) = @_;

  # 初始化 dyNatInfo 标量
  my $dyNatInfo;
  for my $natInfo ( values %{$param} ) {

    # 情况1：静态NAT
    if ( $natInfo->{"natInfo"}{"natType"} eq 'static' ) {
      $self->createStaticNat($natInfo);
    }

    # 情况2：动态NAT
    else {
      $dyNatInfo->{$type}{$natInfo->{"natInfo"}}{$natInfo->{"realIp"}} = $natInfo;
    }
  }

  # 如果存在 dyNatInfo 则开始创建动态 NAT
  if ( defined $dyNatInfo ) {
    $self->createDyNat($dyNatInfo);
  }
} ## end sub createNat

#--------------------------------------- ---------------------------------------
# createStaticNat 创建静态NAT
#------------------------------------------------------------------------------
sub createStaticNat {
  my ( $self, $natInfo ) = @_;

  use Mojo::Util qw(dumper);
  say dumper $natInfo;

  # 大网-外部实际可见IP
  my $natIp = $natInfo->{"natInfo"}{"natIp"};

  # 私网-配置在服务器的真实IP
  my $realIp = $natInfo->{"realIp"};

  # 配置解析对象
  my $parser = $self->{"searcherReportFwInfo"}{"parser"};

  # 检查是否已定义地址名称
  my $searcher   = Firewall::Policy::Searcher::Topsec->new();
  my $natIpName  = $searcher->getAnAddressName( $parser, undef, $natIp );
  my $realIpName = $searcher->getAnAddressName( $parser, undef, $realIp );

  # 判断是否已存在 natIpName realIpName
  $natIpName = ( defined $natIpName ) ? $natIpName->[0] : $self->createAddress($natIp);
  $realIpName
    = ( defined $realIpName )            ? $realIpName->[0]
    : exists $self->{"address"}{$realIp} ? $self->{"address"}{$realIp}
    :                                      $self->createAddress($realIp);

  #综合 NAT 放行生成策略
  my $natDirection = $natInfo->{"natInfo"}{"natDirection"};
  if ( defined $natDirection ) {
    my ( $fromZone, $toZone )
      = ( $self->{"searcherReportFwInfo"}{"fromZone"}, $self->{"searcherReportFwInfo"}{"toZone"} );

    # 情况1：目的地址NAT
    if ( $natDirection eq 'destination' ) {
      my $zoneStr = "srcarea '$fromZone ' dstarea '$toZone '";
      my $cmdStr  = "nat policy add $zoneStr orig-dst '$natIpName ' trans-dst '$realIpName '";
      $self->addToCommandText($cmdStr);
    }

    #情况2：源地址NAT
    elsif ( $natDirection eq 'source' ) {
      my $zoneStr = "srcarea '$fromZone ' dstarea '$toZone '";
      my $cmdStr  = "nat policy add $zoneStr orig-src '$realIpName ' trans-src '$natIpName '";
      $self->addToCommandText($cmdStr);
    }
  }
} ## end sub createStaticNat

#------------------------------------------------------------------------------
# createDyNat 动态生成 NAT策略
#------------------------------------------------------------------------------
sub createDyNat {
  my ( $self, $param ) = @_;
  use Mojo::Util qw(dumper);
  say dumper $param;

  # 初始化相关变量
  my $parser   = $self->{"searcherReportFwInfo"}{"parser"};
  my $searcher = Firewall::Policy::Searcher::Topsec->new();
  my ( $fromZone, $toZone )
    = ( $self->{"searcherReportFwInfo"}{"fromZone"}, $self->{"searcherReportFwInfo"}{"toZone"} );
  my $zoneStr = "srcarea '$fromZone ' dstarea '$toZone '" || "";

  # 遍历 param
  my %natIpInfo;
  for my $natDirection ( keys %{$param} ) {
    for my $natInfo ( values %{$param->{$natDirection}} ) {
      for my $nat ( values %{$natInfo} ) {
        my $natIp = $nat->{"natInfo"}{"natIp"};
        push @{$natIpInfo{$natIp}{"realIp"}}, $nat->{"realIp"};
        $natIpInfo{$natIp}{"natOption"} = $nat->{"natInfo"}{"natOption"} || undef;
      }

      # 遍历 natIpInfo
      for my $natIp ( keys %natIpInfo ) {
        my $cmdStr = "nat policy add $zoneStr";

        # 计算大网地址对象
        my $natIpName = $searcher->getAnAddressName( $parser, undef, $natIp );
        $natIpName = ( defined $natIpName ) ? $natIpName->[0] : $self->createAddress($natIp);

        # 计算私网地址对象
        my $realIpStr = "'";
        for my $realIp ( @{$natIpInfo{$natIp}{"realIp"}} ) {
          my $realIpName = $searcher->getAnAddressName( $parser, undef, $realIp );

          # 不存在则新增
          if ( not defined $realIpName ) {

            # 优先匹配已有信息
            $realIpName = $self->{"address"}{$realIp};

            # 如未匹配则新建
            $realIpName = $self->createAddress($realIp) unless defined $realIpName;
          }

          # 已定义则复用
          else {
            $realIpName = $realIpName->[0];
          }
          $realIpStr .= $realIpName . " ";
        } ## end for my $realIp ( @{$natIpInfo...})
        $realIpStr .= "'";

        # 情况1：源地址NAT
        if ( $natDirection eq 'natSrc' ) {
          $cmdStr .= " orig-src '" . $realIpStr;
          if ( defined $natIpInfo{$natIp}{"natOption"} and $natIpInfo{$natIp}{"natOption"} =~ /d/ ) {
            $cmdStr .= " orig-dst '";
            for my $dstIp ( keys %{$self->{"searcherReportFwInfo"}{"dstMap"}} ) {
              my $dstIpName = $searcher->getAnAddressName( $parser, undef, $dstIp );
              if ( not defined $dstIpName ) {
                $dstIpName = $self->{"address"}{$dstIp};
                $dstIpName = $self->createAddress($dstIp) if not defined $dstIpName;
              }
              else {
                $dstIpName = $dstIpName->[0];
              }
              $cmdStr .= $dstIpName . " ";
            }
            $cmdStr .= "'";
          }

          $cmdStr .= " trans-src $natIpName";
          $self->addToCommandText($cmdStr);
        } ## end if ( $natDirection eq ...)

        # 情况2：目的地址NAT
        elsif ( $natDirection eq 'natDst' ) {
          if ( defined $natIpInfo{$natIp}{"natOption"} and $natIpInfo{$natIp}{"natOption"} =~ /s/ ) {
            $cmdStr .= " orig-src '";
            for my $srcIp ( keys %{$self->{"searcherReportFwInfo"}{"srcMap"}} ) {
              my $srcIpName = $searcher->getAnAddressName( $parser, undef, $srcIp );
              if ( not defined $srcIpName ) {
                $srcIpName = $self->{"address"}{$srcIp};
                $srcIpName = $self->createAddress($srcIp) if not defined $srcIpName;
              }
              else {
                $srcIpName = $srcIpName->[0];
              }
              $cmdStr .= $srcIpName . " ";
            }
            $cmdStr .= "'";
          }
          $cmdStr .= " orig-dst '" . $realIpStr . "'";
          $cmdStr .= " trans-dst $natIpName";
          $self->addToCommandText($cmdStr);
        } ## end elsif ( $natDirection eq ...)
      } ## end for my $natIp ( keys %natIpInfo)
    } ## end for my $natInfo ( values...)
  } ## end for my $natDirection ( ...)
} ## end sub createDyNat

#------------------------------------------------------------------------------
# createSrc 创建源地址对象
#------------------------------------------------------------------------------
sub createSrc {
  my ( $self, $addr ) = @_;
  return $self->createAddress($addr);
}

#------------------------------------------------------------------------------
# createDst 创建目的地址对象
#------------------------------------------------------------------------------
sub createDst {
  my ( $self, $addr ) = @_;
  return $self->createAddress($addr);
}

#------------------------------------------------------------------------------
# createSrv 创建服务端口对象
#------------------------------------------------------------------------------
sub createSrv {
  my ( $self, $srv ) = @_;
  return $self->createService($srv);
}

#------------------------------------------------------------------------------
# createAddress 具体实现创建地址对象
#------------------------------------------------------------------------------
sub createAddress {
  my ( $self, $addr ) = @_;

  # 分割 子网/掩码 格式的IP
  my ( $ip, $mask ) = split( '/', $addr );
  my $ipObj = Firewall::Utils::Ip->new();

  # 初始化相关变量
  my ( $cmdStr, $addressName, $ipString, $ipMin, $ipMax );

  # 情况1：连续地址
  if ( not defined $mask ) {
    if ( $ip =~ /(\d+\.)(\d+\.)(\d+\.)(\d+)-(\d+)/ ) {
      ( $ipMin, $ipMax ) = ( $1 . $2 . $3 . $4, $1 . $2 . $3 . $5 );
      $addressName = "range_$ip";
      $cmdStr      = "define range add name $addressName ip1 $ipMin ip2 $ipMax";
    }
  }

  # 情况2：主机地址
  elsif ( $mask == 32 ) {
    $ipString    = $ip;
    $addressName = "host_$ip";
    $cmdStr      = "define host add name $addressName ipaddr '$ip '";
  }

  # 情况3：掩码为0
  elsif ( $mask == 0 ) {
    return 'any';
  }

  # 情况4：将地址转换为子网格式
  else {
    $ipString = $ipObj->getNetIpFromIpMask( $ip, $mask );
    my $maskStr = $ipObj->changeMaskToIpForm($mask);
    $addressName = "net_$ipString/$mask";
    $cmdStr      = "define subnet add name $addressName ipaddr $ip mask $maskStr";
  }
  $self->{"address"}{$addr} = $addressName;
  $self->addToCommandText($cmdStr);

  # 返回计算结果
  return $addressName;
} ## end sub createAddress

#------------------------------------------------------------------------------
# Firewall::Policy::Designer::Topsec 通用属性
#------------------------------------------------------------------------------
sub createService {
  my ( $self, $srv ) = @_;

  # 分割服务端口为 协议、端口
  my ( $protocol, $port ) = split( '/', $srv );
  $protocol = lc $protocol;

  # 跳过不支持的 protocol 字段
  return if $protocol !~ /^(tcp|udp|icmp|\d+)$/;

  # 转换协议为具体的数字
  my $protoNum;
  $protoNum = 6         if $protocol eq 'tcp';
  $protoNum = 17        if $protocol eq 'udp';
  $protoNum = 1         if $protocol eq 'icmp';
  $protoNum = $protocol if $protocol =~ /^\d+$/;

  #
  my ( $cmdStr, $serviceName );
  if ( $port =~ /^(?<portMin>\d+)\-(?<portMax>\d+)$/o ) {
    $serviceName = lc($protocol) . "_" . $+{portMin} . "_" . $+{portMax};
    $cmdStr      = "define service add name $serviceName protocol $protoNum port $+{portMin} port2 $+{portMax}";
  }
  elsif ( $port =~ /^\d+$/o ) {
    $serviceName = lc($protocol) . "_" . $port;
    $cmdStr      = "define service add name $serviceName protocol $protoNum port $port";
  }
  else {
    confess "ERROR: $port is not a port";
  }
  $self->addToCommandText($cmdStr);

  # 返回计算结果
  $serviceName;
} ## end sub createService

__PACKAGE__->meta->make_immutable;
1;
