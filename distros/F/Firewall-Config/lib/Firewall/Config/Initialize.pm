package Firewall::Config::Initialize;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use POSIX;
use Carp;
use Time::HiRes;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Config::Connector;
use Firewall::Config::Dao::Parser;
use Firewall::Utils::Date;
use Firewall::Utils::Ip;
use Firewall::Config::Content::Static;

#------------------------------------------------------------------------------
# 数据库联结插件
#------------------------------------------------------------------------------
has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', );

#------------------------------------------------------------------------------
# 初始化防火墙
#------------------------------------------------------------------------------
sub initFirewall {
  my ( $self, $param ) = @_;
  my $conf;
  my $fwId   = $param->{fwId};
  my $fwInfo = $self->getFwInfo($fwId);

  # say dumper $fwInfo;
  my $fwName = $fwInfo->{$fwId}{fwName};
  my $fwType = $fwInfo->{$fwId}->{fwType};
  my $vdom   = $fwInfo->{$fwId}->{vdom};
  if ( $param->{initType} eq 'connect' ) {
    eval { $conf = $self->getConfById( $fwInfo->{$fwId} ); };
    if ( !!$@ ) {
      $@ =~ /^(?<error>.+?)\s+at\s+/im;
      my $err = $+{error};
      my $sql = "update fw_info set fw_state=3,fw_error='$err' where fw_id = $fwId";
      $self->dbi->execute($sql);
      return {success => 0, reason => $err};
    }
  }
  elsif ( $param->{initType} eq 'import' ) {
    if ( open( my $file_h, $param->{file} ) ) {
      my @config;
      while ( my $str = <$file_h> ) {
        chomp $str;
        push @config, $str;
      }
      $conf = Firewall::Config::Content::Static->new(
        fwId   => $fwId,
        fwName => $fwName,
        config => \@config,
        fwType => $fwType
      );
    }
    else {
      my $sql = "update fw_info set fw_state=3,fw_error='open file $param->{file} fail' where fw_id = $fwId";
      $self->dbi->execute($sql);
      return {success => 0, reason => "open file $param->{file} fail"};
    }
  }

  eval { $self->saveAndParseConfig( {fwId => $fwId, type => $fwType, conf => $conf, vdom => $vdom} ); };
  if ( !!$@ ) {

    # confess $@;
    $@ =~ /^(?<error>.+?)\s+at\s+/im;
    my $err = $+{error};
    my $sql = "update fw_info set fw_state=3,fw_error='$err' where fw_id = $fwId";
    $self->dbi->execute($sql);
    return {success => 0, reason => $err};
  }
  my $sql = "update fw_info set fw_state=2 where fw_id = $fwId";
  $self->dbi->execute($sql);
  return {success => 1};
}

#------------------------------------------------------------------------------
# 更新防火墙网段信息
#------------------------------------------------------------------------------
sub updateNetwork {
  my ( $self, $fwId ) = @_;

  my @tables = ( 'fw_network_main', 'fw_network_private' );
  for my $table (@tables) {
    my $sql      = "select fw_id,zone,addr_range from $table where fw_id=$fwId";
    my $networks = $self->dbi->execute($sql)->all;
    for my $network ( @{$networks} ) {
      my ( $min, $max );
      if ( $network->{addr_range} =~ /\d+\.\d+\.\d+\.\d+\/\d+/ ) {
        my ( $ip, $mask ) = split( '/', $network->{addr_range} );
        ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
      }
      elsif ( $network->{addr_range} =~ /\d+\.\d+\.\d+\.\d+-\d+\.\d+\.\d+\.\d+/ ) {
        my ( $minIp, $maxIp ) = split( '-', $network->{addr_range} );
        ( $min, $max ) = Firewall::Utils::Ip->new->getRangeFromIpRange( $minIp, $maxIp );
      }
      else {
        return {success => 0, reason => "ipaddr format is wrong!"};
      }
      my $sql
        = "update $table set addr_min=$min,addr_max=$max where fw_id = :fwId and zone= :zone and addr_range= :range";
      $self->dbi->execute( $sql,
        {fwId => $network->{fw_id}, zone => $network->{zone}, range => $network->{addr_range}} );
    }
  }
  $self->dbi->disconnect;
  return {success => 1};
}

#------------------------------------------------------------------------------
# 保存并解析防火墙配置，结构化数据入库
#------------------------------------------------------------------------------
sub saveAndParseConfig {
  my ( $self, $param ) = @_;
  my ( $fwId, $type, $conf ) = @{$param}{qw/fwId type conf/};
  my $sonDbi = $self->dbi->clone;

  my $predefinedService;
  eval(
    "use Firewall::Config::Dao::PredefinedService::$type; \$predefinedService = Firewall::Config::Dao::PredefinedService::$type->new( dbi => \$sonDbi )"
  );
  confess $@ if !!$@;
  $predefinedService = $predefinedService->load($fwId);

  use Firewall::Config::Dao::Config;
  my $daoConf         = Firewall::Config::Dao::Config->new( dbi => $sonDbi, conf => $conf );
  my $isConfigChanged = $daoConf->save;

  #return unless $isConfigChanged;

  my $parser;
  eval(
    "use Firewall::Config::Parser::$type; \$parser = Firewall::Config::Parser::$type->new(config => \$conf, preDefinedService => \$predefinedService);"
  );
  confess $@ if !!$@;

  if ( $type eq 'Fortinet' ) {
    $parser->{vdom} = $param->{vdom} // 'root';
  }
  $parser->parse();
  my $dao = Firewall::Config::Dao::Parser->new( dbi => $sonDbi, parser => $parser );

  #say dumper $parser->elements->zone;
  $dao->save;
}

#------------------------------------------------------------------------------
# 查询防火墙运行配置
#------------------------------------------------------------------------------
sub getConfById {
  my ( $self, $fwInfoEachId ) = @_;
  my ( $fwId, $manageIp, $username, $passwd, $fwType, $connectionType, $fwName )
    = @{$fwInfoEachId}{qw/fwId manageIp username passwd fwType connectionType fwName/};
  my $className = "Firewall::Config::Connector::$fwType";
  my ( $config, $conn );
  eval("use $className;\$conn = \$className->new();");
  croak $@ if !!$@;

  my $configStr;
  eval { $configStr = $conn->$connectionType( host => $manageIp, user => $username, password => $passwd ); };
  confess $@ if !!$@;

  $config = [ split( /\n/, $configStr ) ];
  my $conf
    = Firewall::Config::Content::Static->new( fwId => $fwId, fwName => $fwName, config => $config, fwType => $fwType );
  return $conf;
}

#------------------------------------------------------------------------------
# 查询防火墙登录信息
#------------------------------------------------------------------------------
sub getFwInfo {
  my $self         = shift;
  my $fw_id        = shift;
  my $subCondition = defined $fw_id ? "fw_id=$fw_id" : "";
  my $fwInfo       = $self->dbi->execute(
    "select i.fw_id,
        i.fw_name,
        (select b.basekey_name from fw_basekey b where b.basekey_id = i.connection_type) as connection_type,
        (select b.basekey_name from fw_basekey b where b.basekey_id = i.fw_type) as fw_type,
        i.username,
        i.passwd,
        i.state,
        i.manage_ip,
        i.vdom
        from FW_INFO i
        where $subCondition"
  )->all;
  $self->dbi->disconnect;

  my ( %fwInfoIdAsKey, %fwInfoIpAsKey );
  foreach (@$fwInfo) {

    # $fwInfoIdAsKey{$_->{'FW_ID'}} = $_;
    @{$fwInfoIdAsKey{$_->{'fw_id'}}}{qw/fwId fwName connectionType fwType username passwd state manageIp vdom/}
      = @{$_}{qw/fw_id fw_name connection_type fw_type username passwd state manage_ip vdom/};
    $fwInfoIdAsKey{$_->{'fw_id'}}{fwType} = ucfirst lc $fwInfoIdAsKey{$_->{'fw_id'}}{fwType};
  }
  return \%fwInfoIdAsKey;
}

__PACKAGE__->meta->make_immutable;
1;

