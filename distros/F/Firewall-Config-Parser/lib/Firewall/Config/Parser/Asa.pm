package Firewall::Config::Parser::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use experimental qw( smartmatch );

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Parser::Role 觉得，直接使用其属性和方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Parser::Role';

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element 具体元素规范
#------------------------------------------------------------------------------
use Firewall::Config::Element::AddressGroup::Asa;
use Firewall::Config::Element::ServiceGroup::Asa;
use Firewall::Config::Element::ProtocolGroup::Asa;
use Firewall::Config::Element::Schedule::Asa;
use Firewall::Config::Element::Rule::Asa;
use Firewall::Config::Element::Route::Asa;
use Firewall::Config::Element::Zone::Asa;
use Firewall::Config::Element::Interface::Asa;
use Firewall::Config::Element::StaticNat::Asa;
use Firewall::Config::Element::NatPool::Asa;
use Firewall::Config::Element::DynamicNat::Asa;
use Firewall::Utils::Ip;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Asa 通用属性
#------------------------------------------------------------------------------
has aclLineNumbers => ( is => 'ro', isa => 'HashRef[Int]', default => sub { {} }, );

#------------------------------------------------------------------------------
# 定义 Firewall::Config::Parser::Asa 配置解析入口函数
# parse 为 Firewall::Config::Parser::Role 角色必须实现的方法
#------------------------------------------------------------------------------
sub parse {
  my $self = shift;
  while ( my $string = $self->nextUnParsedLine ) {
    if    ( $self->isRoute($string) ) { $self->parseRoute($string) }
    elsif ( $self->isInterfaceZone($string) ) {$self->parseInterfaceZone($string)}
    elsif ( $self->isAclGroup($string) ) {$self->parseAclGroup($string)}
    elsif ( $self->isAddressGroup($string) ) {$self->parseAddressGroup($string)}
    elsif ( $self->isServiceGroup($string) ) {$self->parseServiceGroup($string)}
    elsif ( $self->isProtocolGroup($string) ) {$self->parseProtocolGroup($string)}
    elsif ( $self->isSchedule($string) ) {$self->parseSchedule($string)}
    else {$self->ignoreLine}
  }
  $self->goToHeadLine;
  while ( my $string = $self->nextUnParsedLine ) {
    if    ( $self->isStaticNat($string) ) { $self->parseStaticNat($string) }
    elsif ( $self->isRule($string) )      { $self->parseRule($string) }
    elsif ( $self->isNatPool($string) )   { $self->parseNatPool($string) }
    elsif ( $self->isDynamicNat($string) ) {$self->parseDynamicNat($string)}
    elsif ( $self->isNewNat($string) ) {$self->parseNewNat($string)}
    else {$self->ignoreLine}
  }
} ## end sub parse

sub isNewNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /nat\s+\((?<realZone>\S+),(?<natZone>\S+)\)(\s+after-auto)?\s+source/ ) {
    return 1;
  }
  else {
    return;
  }
}

sub parseNewNat {
  my ( $self, $string ) = @_;
  $self->{version} = '8.3';
  my $ippat = '\d+\.\d+\.\d+\.\d+';
  if (
    $string =~ /nat\s+\((?<realZone>\S+),(?<natZone>\S+)\)(\s+after-auto)?\s+source\s+(?<snatType>dynamic|static)\s+
        (?<src>\S+)\s+(?:(?<int1>interface)|(pat-pool\s+(?<spatObj>\S+))|(?<snatObj>\S+))(\s+(?<int2>interface))?
        (?:\s+destination\s+static\s+(?<dstnat>\S+)\s+(?<dst>\S+))?
        (?:\s+service\s+(?<natSrv>\S+)\s+(?<srv>\S+))?/oxi
    )
  {
    my $realZone = $+{realZone};
    my $natZone  = $+{natZone};
    my $snatType = $+{snatType};
    my $src      = $+{src};
    my $natInt   = $+{int1};
    my $spatObj  = $+{spatObj};
    my $snatObj  = $+{snatObj};
    my $dstnat   = $+{dstnat};
    my $dst      = $+{dst};
    my $natSrv   = $+{natSrv};
    my $srv      = $+{srv};

    if ( $snatType eq 'static' ) {
      if ( defined $snatObj and $snatObj ne $src ) {
        my %params;
        $params{config}   = $string;
        $params{realZone} = $realZone;
        $params{natZone}  = $natZone;
        my $srcAddr = $self->getAddressGroup($src);
        my $natAddr = $self->getAddressGroup($snatObj);
        if ( not defined $dstnat and not defined $natSrv ) {
          $params{natIp}       = $snatObj;
          $params{realIpRange} = $srcAddr->range;
          $params{natIpRange}  = $natAddr->range;
          my $staticNat = Firewall::Config::Element::StaticNat::Asa->new(%params);
          $self->addElement($staticNat);
        }
        elsif ( defined $natSrv ) {
          $params{natDirection} = 'destination';
          my $srv    = $self->getServiceGroup($natSrv);    #real_src_mapped_dest_svc,作为源的真实SRV,目的NAT SRV
          my $natSrv = $self->getServiceGroup($srv);
          $params{srvRange}    = $srv->range;
          $params{natSrvRange} = $natSrv->range;
          $params{natDstRange} = $natAddr->range;
          $params{dstIpRange}  = $srcAddr->range;
          $params{fromZone}    = $natZone;
          $params{toZone}      = $realZone;
          $params{ruleName}    = $snatObj;
          my $dyNat = Firewall::Config::Element::DynamicNat::Asa->new(%params);
          $self->addElement($dyNat);
        }
      }
      elsif ( defined $snatObj and $snatObj eq $src ) {
        if ( defined $dstnat and $dstnat ne $dst and defined $natSrv ) {
          my %params;
          $params{config} = $string;
          if ( $src =~ /any/ ) {
            $params{srcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          }
          else {
            my $srcAddr = $self->getAddressGroup($src);
            $params{srcIpRange} = $srcAddr->range;
          }
          $params{realZone}     = $natZone;
          $params{natZone}      = $realZone;
          $params{natDirection} = 'destination';
          my $srvAddr    = $self->getServiceGroup($srv);      #real_src_mapped_dest_svc,作为源的真实SRV,目的NAT SRV
          my $natSrvAddr = $self->getServiceGroup($natSrv);
          my $dstAddr    = $self->getAddressGroup($dst);
          my $natAddr    = $self->getAddressGroup($dstnat);
          $params{srvRange}    = $srvAddr->range;
          $params{natSrvRange} = $natSrvAddr->range;
          $params{natDstRange} = $natAddr->range;
          $params{dstIpRange}  = $dstAddr->range;
          $params{fromZone}    = $realZone;
          $params{toZone}      = $natZone;
          $params{ruleName}    = $dstnat;
          my $dyNat = Firewall::Config::Element::DynamicNat::Asa->new(%params);
          $self->addElement($dyNat);
        } ## end if ( defined $dstnat and...)
      } ## end elsif ( defined $snatObj ...)
    }
    elsif ( $snatType eq 'dynamic' ) {
      my %params;
      $params{config}       = $string;
      $params{fromZone}     = $realZone;
      $params{toZone}       = $natZone;
      $params{natDirection} = 'source';
      my $srcAddr = $self->getAddressGroup($src);
      $params{srcIpRange} = $srcAddr->range;
      if ( defined $snatObj and $snatObj ne $src or defined $spatObj ) {
        $params{natZone} = $natZone;
        my $srcAddr = $self->getAddressGroup($src);
        my $natAddr = $self->getAddressGroup($snatObj) if defined $snatObj;
        $natAddr             = $self->getAddressGroup($spatObj) if defined $spatObj;
        $params{natSrcRange} = $natAddr->range;
        $params{ruleName}    = $snatObj if defined $snatObj;
        $params{ruleName}    = $spatObj if defined $spatObj;
      }
      if ( defined $natInt ) {
        my $interface = ( values %{$self->getZone( $params{natZone} )->interfaces} )[0];
        $params{natSrcRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, 32 );
        $params{ruleName}    = $src;
      }
      my $dyNat = Firewall::Config::Element::DynamicNat::Asa->new(%params);
      $self->addElement($dyNat);
      if ( defined $dst ) {
        my $dstAddr = $self->getAddressGroup($dst);
        $dyNat->{dstIpRange} = $dstAddr->range;
      }
    } ## end elsif ( $snatType eq 'dynamic')
  } ## end if ( $string =~ ...)
} ## end sub parseNewNat

#nat (corporation) 121 access-list 121
sub isDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^nat \s+ \( \S+\)\s+ (?<poolId>\d+)\s+/ox and $+{poolId} != 0 ) {
    $self->setElementType('dynamicNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getDynamicNat {
  my ( $self, $ruleName, $aclName ) = @_;
  return $self->getElement( 'dynamicNat', $ruleName, $aclName );
}

sub parseDynamicNat {
  my ( $self, $string ) = @_;
  my %param;
  $param{config} = $string;
  $param{fwId}   = $self->fwId;
  if ( $string =~ /^nat\s+\((?<zone>\S+)\)\s+(?<poolName>\S+)\s+access-list\s+(?<aclName>\S+)\s*$/ox ) {
    $param{fromZone} = $+{zone};
    $param{ruleName} = $+{poolName};
    $param{aclName}  = $+{aclName};
    my $natPool = $self->getNatPool( $+{poolName} );
    if ( not defined $natPool ) {
      confess "配置未分析完整";
    }
    $param{natSrcPool}  = $natPool;
    $param{natSrcRange} = $natPool->poolRange;
    $param{toZone}      = $natPool->zone;
    my $dynamicNat = Firewall::Config::Element::DynamicNat::Asa->new(%param);
    my $ruleIndex  = $self->elements->{rule};
    for my $rule ( values %{$ruleIndex} ) {
      if ( $rule->aclName eq $+{aclName} ) {
        $dynamicNat->srcIpRange->mergeToSet( $rule->srcAddressGroup->range );
        $dynamicNat->dstIpRange->mergeToSet( $rule->dstAddressGroup->range );
      }
    }
    $self->addElement($dynamicNat);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseDynamicNat

# global (outside) 131 172.16.18.44
sub isNatPool {
  my ( $self, $string ) = @_;
  if ( $string =~ /^global \s+ \( (\S+)\s+/ox ) {
    $self->setElementType('natPool');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getNatPool {
  my ( $self, $poolName ) = @_;
  return $self->getElement( 'natPool', $poolName );
}

sub parseNatPool {
  my ( $self, $string ) = @_;
  my %param;
  $param{fwId}   = $self->fwId;
  $param{config} = $string;

  # global (outside) 131 172.16.18.44
  if ( $string =~ /^global\s+\((?<zone>\S+)\)\s+(?<poolName>\S+)\s+(?<poolIp>.+?)\s*$/ox ) {
    $param{zone}     = $+{zone};
    $param{poolName} = $+{poolName};
    my $poolIp = $+{poolIp};
    if ( $poolIp =~ /^\d+\.\d+\.\d+\.\d+$/ox ) {
      $param{poolIp} = $poolIp . '/32';
    }
    elsif ( $poolIp =~ /^\d+\.\d+\.\d+\.\d+-\d+\.\d+\.\d+\.\d+$/ox ) {
      $param{poolIp} = $poolIp;
    }
    elsif ( $poolIp =~ /^(?<ip>\d+\.\d+\.\d+\.\d+) \s+ netmask \s+ (?<mask>\d+\.\d+\.\d+\.\d+)$/ox ) {
      my $mask = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
      $param{poolIp} = $+{ip} . '/' . $mask;
    }
    elsif ( $poolIp =~ /^interface$/ox ) {
      my $zone = $self->getZone( $param{zone} );
      $param{poolIp} = ( ( values %{$zone->interfaces} )[0] )->{ipAddress} . '/32';
    }
    else {
      $self->warn("$poolIp 分析不出来\n");
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
  my $natPool = Firewall::Config::Element::NatPool::Asa->new(%param);
  $self->addElement($natPool);
} ## end sub parseNatPool

sub isStaticNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^static \s+ \( (\S+)\s+/ox ) {
    $self->setElementType('staticNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getStaticNat {
  my ( $self, $natIp ) = @_;
  return $self->getElement( 'staticNat', $natIp );
}

=example

  static (investment,outside) 201.44.12.31  access-list 1001
  static (corporation,outside) 172.16.16.30  access-list 139
  static (outside,corporation) 192.168.2.10  access-list 829
  static (investment,outside) 10.17.130.131  access-list 3874
  static (corporation,outside) 172.16.17.220 172.29.4.100 netmask 255.255.255.255
  static (corporation,outside) 172.16.17.221 172.29.4.99 netmask 255.255.255.255

=cut

sub parseStaticNat {
  my ( $self, $string ) = @_;
  my %param;
  $param{fwId}   = $self->fwId;
  $param{config} = $string;
  if ( $string
    =~ /^static\s+\((?<realZone>[^,]+),(?<natZone>[^)]+)\)\s+(?<natIp>\S+)\s+access-list\s+(?<aclName>\S+)\s*$/ox )
  {
    my $ruleIndex = $self->elements->{rule};
    my $aclName   = $+{aclName};
    $param{aclName}     = $aclName;
    $param{realZone}    = $+{realZone};
    $param{natZone}     = $+{natZone};
    $param{natIp}       = $+{natIp};
    $param{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natIp}, 32 );
    $param{realIpRange} = Firewall::Utils::Set->new;
    $param{dstIpRange}  = Firewall::Utils::Set->new;

    foreach my $rule ( values %{$ruleIndex} ) {
      if ( $rule->aclName eq $aclName ) {
        $param{realIpRange}->mergeToSet( $rule->srcAddressGroup->range );
        $param{dstIpRange}->mergeToSet( $rule->dstAddressGroup->range );
      }
    }
  }
  elsif ( $string
    =~ /^static\s+\((?<realZone>[^,]+),(?<natZone>[^)]+)\)\s+(?<natIp>\S+)\s+(?<realIp>\S+)\s+netmask\s+(?<mask>\S+)\s*$/ox
    )
  {
    $param{realZone}    = $+{realZone};
    $param{natZone}     = $+{natZone};
    $param{natIp}       = $+{natIp};
    $param{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natIp},  $+{mask} );
    $param{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{realIp}, $+{mask} );
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
  my $staticNat = Firewall::Config::Element::StaticNat::Asa->new(%param);
  $self->addElement($staticNat);
} ## end sub parseStaticNat

#access-group outside_access_in in interface outside
sub isAclGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^access-group\s+\S+\s+(in|out)\s+interface\s+\S+\s*/ox ) {
    $self->setElementType('aclGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

#access-group outside_access_in in interface outside
sub parseAclGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^access-group\s+(?<aclName>\S+)\s+in\s+interface\s+(?<zoneName>\S+)\s*$/ox ) {
    my $zone = $self->getZone( $+{zoneName} );
    $self->{aclZone}{$+{aclName}} = $+{zoneName};
    if ( defined $zone ) {
      $zone->{aclName} = $+{aclName};
    }
    else {
      $self->warn("$string 分析不出来!zone $+{zoneName}不存在!\n");
    }
  }
}

sub isInterfaceZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^interface\s+\S+\s*/ox ) {
    $self->setElementType('interfaceZone');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getInterface {
  my ( $self, $name ) = @_;
  return $self->getElement( 'interface', $name );
}

sub getZone {
  my ( $self, $name ) = @_;
  return $self->getElement( 'zone', $name );
}

sub parseInterfaceZone {
  my ( $self, $string ) = @_;

=example

  interface GigabitEthernet0/1
   nameif corporation
   security-level 100
   ip address 192.168.201.28 255.255.255.248 standby 192.168.201.29
  !

=cut

  if ( $string =~ /^interface\s+(?<interfaceName>\S+)\s*$/ox ) {
    my $interfaceName = $+{interfaceName};
    my $zoneName;
    my $ipAddress;
    my $mask;
    my $config = $string;
    while ( my $string = $self->nextUnParsedLine ) {
      $config .= "\n" . $string;
      if ( $string =~ /^\s*nameif\s+(?<zoneName>\S+)\s*$/ox ) {
        $zoneName = $+{zoneName};
      }
      elsif ( $string =~ /^\s*ip\s+address\s+(?<ipAddress>\S+)\s+(?<maskStr>\S+)\s*/ox ) {
        $ipAddress = $+{ipAddress};
        $mask      = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{maskStr} );
      }
      elsif ( $string =~ /^!/ ) {
        if ( defined $zoneName ) {
          my $interface = Firewall::Config::Element::Interface::Asa->new(
            fwId     => $self->fwId,
            name     => $interfaceName,
            zoneName => $zoneName,
            config   => $config
          );
          my $zone
            = Firewall::Config::Element::Zone::Asa->new( fwId => $self->fwId, name => $zoneName, config => $config );
          $self->addElement($zone);
          if ( defined $ipAddress ) {
            $interface->{interfaceType} = 'layer3';
            $interface->{ipAddress}     = $ipAddress;
            $interface->{mask}          = $mask;
            my $route = Firewall::Config::Element::Route::Asa->new(
              fwId     => $self->fwId,
              network  => $ipAddress,
              mask     => $mask,
              zoneName => $zoneName
            );
            $interface->addRoute($route);
            $self->addElement($route);
            $self->addElement($interface);
          }
          $zone->addInterface($interface);
        } ## end if ( defined $zoneName)
        return;
      } ## end elsif ( $string =~ /^!/ )
    } ## end while ( my $string = $self...)
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseInterfaceZone

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /^route\s+\S+\s+/ox ) {
    $self->setElementType('route');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRoute {
  my ( $self, $network, $mask ) = @_;
  return $self->getElement( 'route', $network, $mask );
}

sub parseRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /^route\s+(?<zoneName>\S+)\s+(?<network>\S+)\s+(?<maskStr>\S+)\s+(?<nextHop>\S+)\s* /ox ) {
    my $mask  = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{maskStr} );
    my $route = Firewall::Config::Element::Route::Asa->new(
      fwId     => $self->fwId,
      network  => $+{network},
      mask     => $mask,
      nextHop  => $+{nextHop},
      zoneName => $+{zoneName},
      config   => $string
    );
    $self->addElement($route);
    my $zone;
    if ( $zone = $self->getZone( $+{zoneName} ) ) {
      $zone->range->mergeToSet( $route->range );
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseRoute

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^(object-group|object)\s+network\s+\S+/ox ) {
    $self->setElementType('addressGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddressGroup {
  my ( $self, $addrGroupName ) = @_;
  return $self->getElement( 'addressGroup', $addrGroupName );
}

sub parseAddressGroup {
  my ( $self, $string ) = @_;
  my $ippat = '\d+\.\d+\.\d+\.\d+';

=example

  object-group network P_88_src
   network-object host 10.12.102.157
   network-object 10.16.0.0 255.255.0.0
   group-object G_openview_mg
  object network MidWare_Deploy
  host 10.21.255.16

  object-group network addrgroup5355
  network-object object range_10.21.4.82-10.21.4.84
  network-object object range_30.16.36.163-30.16.36.170

  object network range_10.21.4.82-10.21.4.84
  range 10.21.4.82 10.21.4.84

=cut

  if ( $string =~ /^(object-group|object)\s+network\s+(?<addrGroupName>\S+)\s*$/ox ) {
    my $addrGroupName = $+{addrGroupName};
    my $addressGroup  = $self->getAddressGroup($addrGroupName);
    if ( not defined $addressGroup ) {
      $addressGroup = Firewall::Config::Element::AddressGroup::Asa->new(
        fwId          => $self->fwId,
        addrGroupName => $addrGroupName,
        config        => $string
      );
      $self->addElement($addressGroup);
    }
    while ( my $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^\s*network-object\s+(?<addrGroupMemberName>\d+\.\d+\.\d+\.\d+\s+\d+\.\d+\.\d+\.\d+)\s*$/ox
        or $string =~ /network-object\s+object\s+(?<addrGroupMemberName>\S+)/
        or $string =~ /^\s*group-object\s+(?<addrGroupMemberName>\S+)\s*$/ox
        or $string =~ /host\s+(?<host>\S+)/ox
        or $string =~ /subnet\s+(?<subnet>\S+)\s+(?<maskStr>\S+)/ox
        or $string =~ /range\s+(?<ip1>\S+)\s+(?<ip2>\S+)/ox )
      {
        $addressGroup->{config} .= "\n" . $string;
        if ( defined $+{addrGroupMemberName} ) {
          my $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $+{addrGroupMemberName} );
          if ( not defined $obj ) {
            $self->warn("addrGroup $addrGroupName 的 addrGroupMember $+{addrGroupMemberName} 不是 addressGroup\n");
          }
          $addressGroup->addAddrGroupMember( $+{addrGroupMemberName}, $obj );
        }
        if ( defined $+{host} ) {
          my $obj = Firewall::Config::Element::Address::Asa->new(
            fwId     => $self->fwId,
            addrName => $+{host},
            ip       => $+{host},
            mask     => 32
          );
          $addressGroup->addAddrGroupMember( $+{host}, $obj );
        }
        if ( defined $+{subnet} ) {
          my $maskStr = $+{maskStr};
          my $subnet  = $+{subnet};
          my $mask    = Firewall::Utils::Ip->new->changeMaskToNumForm($maskStr);
          my $obj     = Firewall::Config::Element::Address::Asa->new(
            fwId     => $self->fwId,
            addrName => $subnet,
            ip       => $subnet,
            mask     => $mask
          );
          $addressGroup->addAddrGroupMember( $subnet, $obj );
        }
        if ( defined $+{ip1} and defined $+{ip2} ) {
          my $iprange = $+{ip1} . '-' . $+{ip2};
          my $obj     = Firewall::Config::Element::Address::Asa->new(
            fwId     => $self->fwId,
            addrName => $iprange,
            iprange  => $iprange
          );
          $addressGroup->addAddrGroupMember( $iprange, $obj );
        }
      }
      elsif (
        $string =~ /nat\s*\((?<realZone>\S+),(?<natZone>\S+)\)\s+
                (?<natType>static|dynamic)\s+
                (?:(?<natIp>$ippat)|pat-pool\s+(?<patObj>\S+)|(?<natObj>\S+))?(\s+(?<interface>interface))?
                (?:\s+service\s+(?<proto>tcp|udp)\s+(?<realport>\d+)\s+(?<natport>\d+))?/oxi
        )
      {
        $self->{version} = '8.3';
        $addressGroup->{refnum} += 1;
        my %params;
        $params{fwId} = $self->fwId;
        my $config = $addressGroup->{config};
        $config .= "\n" . $string;
        $params{config} = $config;
        my $natIp  = $+{natIp};
        my $patObj = $+{patObj};
        my $natObj = $+{natObj};
        my $int    = $+{interface};

        if ( $+{natType} eq 'static' and not defined $+{proto} ) {
          $params{realZone}    = $+{realZone};
          $params{natZone}     = $+{natZone};
          $params{realIpRange} = $addressGroup->range;
          if ( defined $natIp ) {
            $params{natIp}      = $natIp;
            $params{natIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, 32 );
          }
          if ( defined $natObj or defined $patObj ) {
            my $address = $self->getAddressGroup($natObj) if defined $natObj;
            $address = $self->getAddressGroup($patObj) if defined $patObj;
            $address->{refnum} += 1;
            $params{natIp}      = $natObj // $patObj;
            $params{natIpRange} = $address->range;
          }
          if ( defined $int ) {
            my $interface = ( values %{$self->getZone( $params{natZone} )->interfaces} )[0];
            $params{natIp} = $interface->ipAddress if not defined $params{natIp};
            if ( not defined $params{natIpRange} ) {
              $params{natIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, 32 );
            }
            else {
              $params{natIpRange}->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, 32 ) );
            }
          }
          my $staticNat = Firewall::Config::Element::StaticNat::Asa->new(%params);
          $self->addElement($staticNat);
        }
        elsif ( $+{natType} eq 'static' and defined $+{proto} ) {
          $params{fromZone}     = $+{natZone};
          $params{toZone}       = $+{realZone};
          $params{natDirection} = 'destination';
          $params{srcIpRange}   = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          $params{proto}        = $+{proto};
          $params{ruleName}     = $addrGroupName;
          my $realport = $+{realport};
          my $natport  = $+{natport};
          $params{srvRange}    = Firewall::Utils::Ip->new->getRangeFromService( $params{proto} . "/" . $realport );
          $params{natSrvRange} = Firewall::Utils::Ip->new->getRangeFromService( $params{proto} . "/" . $natport );

          if ( defined $natIp ) {
            $params{natIp}       = $natIp;
            $params{natDstRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, 32 );
            $params{dstIpRange}  = $addressGroup->range;
          }
          if ( defined $natObj ) {
            my $address = $self->getAddressGroup($natObj);
            $params{natIp}       = $natObj;
            $params{natDstRange} = $address->range;
            $params{dstIpRange}  = $addressGroup->range;
          }
          if ( defined $int ) {
            my $interface = ( values %{$self->getZone( $params{natZone} )->interfaces} )[0];
            $params{natIp}       = $interface->ipAddress if not defined $params{natIp};
            $params{natDstRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, 32 );
            $params{dstIpRange}  = $addressGroup->range;
          }
          my $dynamicNat = Firewall::Config::Element::DynamicNat::Asa->new(%params);
          $self->addElement($dynamicNat);
        }
        elsif ( $+{natType} eq 'dynamic' ) {
          $params{fromZone}     = $+{realZone};
          $params{toZone}       = $+{natZone};
          $params{natDirection} = 'source';
          $params{dstIpRange}   = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          $params{ruleName}     = $addrGroupName;
          if ( defined $natIp ) {
            $params{natIp}       = $natIp;
            $params{natSrcRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, 32 );
            $params{srcIpRange}  = $addressGroup->range;
          }
          if ( defined $natObj ) {
            my $address = $self->getAddressGroup($natObj);
            $params{natIp}       = $natObj;
            $params{natSrcRange} = $address->range;
            $params{srcIpRange}  = $addressGroup->range;
          }
          if ( defined $int ) {
            my $interface = ( values %{$self->getZone( $params{natZone} )->interfaces} )[0];
            $params{natIp}       = $interface->ipAddress if not defined $params{natIp};
            $params{natSrcRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, 32 );
            $params{srcIpRange}  = $addressGroup->range;
          }
          my $dynamicNat = Firewall::Config::Element::DynamicNat::Asa->new(%params);
          $self->addElement($dynamicNat);
        } ## end elsif ( $+{natType} eq 'dynamic')
      }
      else {
        $self->backtrackLine;
        return;
      }
    } ## end while ( my $string = $self...)
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseAddressGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $addrGroupMemberName ) = @_;
  my $obj;
  if ( $addrGroupMemberName =~ /^host\s+(?<ip>\d+\.\d+\.\d+\.\d+)$/ox
    or $addrGroupMemberName =~ /^(?<ip>\d+\.\d+\.\d+\.\d+)\s+(?<mask>\d+\.\d+\.\d+\.\d+)$/ox )
  {
    my ( $ip, $mask ) = ( $+{ip}, $+{mask} // '255.255.255.255' );
    my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
    $obj = Firewall::Config::Element::Address::Asa->new(
      fwId     => $self->fwId,
      addrName => $addrGroupMemberName,
      ip       => $ip,
      mask     => $maskNum
    );
  }
  else {
    $obj = $self->getAddressGroup($addrGroupMemberName);
    $obj->{refnum} += 1 if defined $obj;
  }
  return $obj;
} ## end sub getAddressOrAddressGroupFromAddrGroupMemberName

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /(object-group|object) \s+ service \s+/ox ) {
    $self->setElementType('serviceGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getServiceGroup {
  my ( $self, $srvGroupName ) = @_;
  return $self->getElement( 'serviceGroup', $srvGroupName );
}

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Asa->createSign( lc($srvName) );
  return ( $self->preDefinedService->{$sign} );
}

sub parseServiceGroup {
  my ( $self, $string ) = @_;

=example

  object-group service P_Scan_service tcp-udp
   port-object eq 1433
   port-object eq https
   port-object range 40000 40050
   group-object tcpabc
  object-group service unix_basic_service
   service-object tcp eq ssh
   service-object tcp eq domain
   service-object udp eq domain
   service-object tcp eq 383
   service-object tcp range ssh 383

=cut

  if ( $string =~ /(object-group|object)\s+service\s+(?<srvGroupName>\S+)(?:\s+(?<protocol>\S+))?\s*$/ox ) {
    my ( $srvGroupName, $protocol ) = ( $+{srvGroupName}, $+{protocol} );
    my $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
      fwId         => $self->fwId,
      srvGroupName => $srvGroupName,
      protocol     => $protocol,
      config       => $string
    );
    $self->addElement($serviceGroup);
    while ( my $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^\s*port-object\s+(?<srvGroupMemberName>eq\s+\S+)\s*$/ox
        or $string =~ /^\s*port-object\s+(?<srvGroupMemberName>range\s+\S+\s+\S+)\s*$/ox
        or $string =~ /^\s*service-object\s+(?<srvGroupMemberName>\S+\s+eq\s+\S+)\s*$/ox
        or $string =~ /^\s*service-object\s+(?<srvGroupMemberName>\S+\s+range\s+\S+\s+\S+)\s*$/ox
        or $string =~ /^\s*group-object\s+(?<srvGroupMemberName>\S+)\s*$/ox
        or $string
        =~ /service\s+(?<protocol>\S+)\s+destination\s+(?<option>eq|range|lt|gt)\s+(?<dstPortMin>\S+)\s+(?<dstPortMax>\S+)?/ox
        )
      {
        $serviceGroup->{config} .= "\n" . $string;
        if ( defined $+{srvGroupMemberName} ) {
          my @protocols = split( /-/, $serviceGroup->protocol // '' );
          my $obj       = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{srvGroupMemberName}, $srvGroupName,
            @protocols );
          $serviceGroup->addSrvGroupMember( $+{srvGroupMemberName}, $obj );
        }
        else {
          my $protocol = $+{protocol};
          my $option   = $+{option};
          my $portMin  = $self->getPortNumber( $+{dstPortMin} );
          my $portMax  = $self->getPortNumber( $+{dstPortMax} ) if defined $+{dstPortMax};
          $portMax = $portMin if $option eq 'eq' or $option eq 'lt';
          $portMax = 65535    if $option eq 'gt';
          $portMin = 1        if $option eq 'lt';
          my $dstPort = "$portMin-$portMax";
          my $srvName = $protocol . "_" . $dstPort;
          my $service = Firewall::Config::Element::Service::Asa->new(
            fwId     => $self->fwId,
            srvName  => $srvName,
            dstPort  => $dstPort,
            protocol => $protocol
          );
          $serviceGroup->addSrvGroupMember( $srvName, $service );
        } ## end else [ if ( defined $+{srvGroupMemberName...})]
      }
      else {
        $self->backtrackLine;
        return;
      }
    } ## end while ( my $string = $self...)
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseServiceGroup

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName, $srvGroupName, @protocols ) = @_;
  my $obj;
  if ( $srvGroupMemberName =~ /^\S+$/ox ) {
    unless ( $obj = $self->getServiceGroup($srvGroupMemberName) ) {
      $self->warn("srvGroup $srvGroupName 的 srvGroupMember $srvGroupMemberName 不是 serviceGroup\n");
    }
    else {
      $obj->{refnum} += 1;
    }
  }
  else {
    my $dstPort;
    if ( $srvGroupMemberName =~ /^(?: (?<protocol>\S+) \s+ )?  eq \s+ (?<dstPort>\S+)$/ox ) {
      @protocols = ( $+{protocol} ) if @protocols == 0;
      $dstPort   = $self->getPortNumber( $+{dstPort} );
    }
    elsif (
      $srvGroupMemberName =~ /^(?: (?<protocol>\S+) \s+ )?  range \s+ (?<dstPortMin>\S+) \s+ (?<dstPortMax>\S+)$/ox )
    {
      @protocols = ( $+{protocol} ) if @protocols == 0;
      my $dstPortMin = $self->getPortNumber( $+{dstPortMin} );
      my $dstPortMax = $self->getPortNumber( $+{dstPortMax} );
      if ( defined $dstPortMin and defined $dstPortMax ) {
        $dstPort = $dstPortMin . ' ' . $dstPortMax;
      }
    }
    if ( defined $dstPort and @protocols > 0 ) {
      $obj = Firewall::Config::Element::Service::Asa->new(
        fwId     => $self->fwId,
        srvName  => $srvGroupMemberName,
        dstPort  => $dstPort,
        protocol => shift @protocols
      );
      for my $protocol (@protocols) {
        $obj->addMeta(
          fwId     => $self->fwId,
          srvName  => $srvGroupMemberName,
          dstPort  => $dstPort,
          protocol => $protocol
        );
      }
    }
    else {
      $self->warn(
        "srvGroup $srvGroupName 的 srvGroupMember ($srvGroupMemberName) 里含有 既不是数字也不是 pre-defined service 的字符串\n");
    }
  } ## end else [ if ( $srvGroupMemberName...)]
  return $obj;
} ## end sub getServiceOrServiceGroupFromSrvGroupMemberName

sub getPortNumber {
  my ( $self, $portString ) = @_;
  my $portNumber;
  confess "dd" if not defined $portString;
  if ( $portString =~ /^\d+$/o ) {
    $portNumber = $portString;
  }
  elsif ( my $service = $self->getPreDefinedService($portString) ) {
    $portNumber = $service->dstPort;
  }
  else {
    $self->warn("$portString 不是数字 也不是 pre-defined service");
  }
  return $portNumber;
}

sub isProtocolGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^object-group \s+ protocol \s+/ox ) {
    $self->setElementType('protocolGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getProtocolGroup {
  my ( $self, $proGroupName ) = @_;
  return $self->getElement( 'protocolGroup', $proGroupName );
}

sub parseProtocolGroup {
  my ( $self, $string ) = @_;

=example

  object-group protocol TCP_UDP
   protocol-object tcp
   protocol-object udp
   group-object pa123

=cut

  if ( $string =~ /^object-group\s+protocol\s+(?<proGroupName>\S+)\s*$/ox ) {
    my $proGroupName = $+{proGroupName};
    my $protocolGroup
      = Firewall::Config::Element::ProtocolGroup::Asa->new( fwId => $self->fwId, proGroupName => $proGroupName );
    $self->addElement($protocolGroup);
    while ( my $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^\s*(?<protocolObjType>protocol-object|group-object )\s+(?<proGroupMemberName>\S+)\s*$/ox ) {
        my $protocolObjType = ( $+{protocolObjType} eq 'protocol-object' ) ? 'protocol' : 'protocolGroup';
        my $obj = $self->getProtocolOrProtocolGroupFromProGroupMemberName( $+{proGroupMemberName}, $protocolObjType );
        if ( not defined $obj ) {
          $self->warn("proGroup $proGroupName 的 proGroupMember $+{proGroupMemberName} 不是 protocolGroup\n");
        }
        $protocolGroup->addProGroupMember( $+{proGroupMemberName}, $obj );
      }
      else {
        $self->backtrackLine;
        return;
      }
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseProtocolGroup

sub getProtocolOrProtocolGroupFromProGroupMemberName {
  my ( $self, $proGroupMemberName, $protocolObjType ) = @_;
  my $obj;
  if ( $protocolObjType eq 'protocol' ) {
    $obj = Firewall::Config::Element::Protocol::Asa->new( fwId => $self->fwId, protocol => $proGroupMemberName );
  }
  else {
    $obj = $self->getProtocolGroup($proGroupMemberName);
  }
  return $obj;
}

sub isSchedule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^time-range \s+/ox ) {
    $self->setElementType('schedule');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getSchedule {
  my ( $self, $schName ) = @_;
  return $self->getElement( 'schedule', $schName );
}

sub parseSchedule {
  my ( $self, $string ) = @_;

=example

  time-range S_20091130
   absolute start 00:00 01 November 2009 end 23:59 30 November 2009
  time-range S20090926
   absolute end 23:59 26 September 2009
  time-range S_20091131
   periodic daily 11:00 to 14:00
  time-range S_20091132
   periodic Monday Thursday 11:30 to 14:00
  time-range S_20091133
   periodic weekdays 11:00 to 14:00
  time-range S_20091134
   periodic weekend 11:00 to 14:00

=cut

  if ( $string =~ /^time-range\s+(?<schName>\S+)\s*$/ox ) {
    my $schName = $+{schName};
    $string = $self->nextUnParsedLine;
    if ( $string =~ /^\s*(?<schType>absolute)(?:\s+start\s+(?<startDate>.+?))?\s+end\s+(?<endDate>.+?)\s*$/ox ) {
      my $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => $self->fwId,
        schName   => $schName,
        schType   => $+{schType},
        startDate => $+{startDate},
        endDate   => $+{endDate}
      );
      $self->addElement($schedule);
    }
    elsif ( $string =~ /^\s*(?<schType>periodic)\s+(?<periodic>.+?)\s+(?<startTime>\S+)\s+to\s+(?<endTime>\S+)\s*$/ox )
    {
      my $schedule = Firewall::Config::Element::Schedule::Asa->new(
        fwId      => $self->fwId,
        schName   => $schName,
        schType   => $+{schType},
        periodic  => $+{periodic},
        startTime => $+{startTime},
        endTime   => $+{endTime},
        config    => $string
      );
      $self->addElement($schedule);
    }
    else {
      $self->warn("$string 分析不出来\n");
      $self->backtrackLine;
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseSchedule

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^access-list\s+(?<aclName>\S+)\s+extended\s+/ox ) {
    $self->setElementType('rule');
    my $aclName = $+{aclName};
    if ( not defined $self->aclLineNumbers->{$aclName} ) {
      $self->aclLineNumbers->{$aclName} = 1;
    }
    else {
      $self->aclLineNumbers->{$aclName}++;
    }
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseRule {
  my ( $self, $string ) = @_;

=example

  access-list inbond extended permit tcp 10.50.0.0 255.255.0.0 host 10.11.100.252 eq 1234 log
  access-list inbond extended permit tcp object-group G_Tech_Terminal_Svr host 10.11.100.53 eq 3389 log
  access-list inbond extended permit tcp host 10.12.104.57 object-group yun_ying_monitor eq 39564
  access-list inbond extended permit object-group TCP_UDP host 10.35.174.115 host 10.11.100.37 object-group Monitor_fw log
  access-list inbond extended permit tcp object-group P_137_net host 10.11.100.37 range 40050 41000
  access-list inbond extended permit udp object-group G_New_Solarwinds_Svr any eq snmp
  access-list inbond extended permit tcp any host 10.11.108.217 range ssh telnet
  access-list inbond extended permit ip host 10.33.30.102 host 10.11.100.37 time-range S_20100418
  access-list outside-to-inside extended permit tcp any host 202.69.21.97 object-group IMC_tcp inactive
  access-list sf extended permit tcp any host 10.37.106.100 eq 135 log time-range S20090926
  access-list inbond extended permit object-group unix_basic_service any object-group unix_basic_client
  access-list outside_in extended permit tcp object MidWare_Deploy object-group LF_F range 30000 49999
  access-list inside_access_in extended permit icmp any any
  access-list inside_access_in extended permit tcp 215.160.152.0 255.255.252.0 object-group addrgroup5355 eq 9092

=cut

  if (
    $string =~ /^access-list
        \s+
        (?<aclName>\S+)
        \s+
        extended
        \s+
        (?<action>\S+)
        \s+

        (?: # match protocol
        (?<protocolObjType> (object-group|object)) \s+ (?<protocolInfo>\S+)
        | (?!object-group) (?<protocolInfo>\S+)
        )

        \s+

        (?: # match source address
        (object-group|object) \s+ (?<srcAddressInfo>\S+)
        | (?<srcAddressInfo> host \s+ \d+\.\d+\.\d+\.\d+ | \d+\.\d+\.\d+\.\d+ \s+ \d+\.\d+\.\d+\.\d+ | any)
        )

        \s+

        (?: #match destination address
        (object-group|object) \s+ (?<dstAddressInfo>\S+)
        | (?<dstAddressInfo> host \s+ \d+\.\d+\.\d+\.\d+ | \d+\.\d+\.\d+\.\d+ \s+ \d+\.\d+\.\d+\.\d+ | any)
        )

        (?: #match service
        \s+
        (?:
        (object-group|object) \s+ (?<serviceInfo>\S+)
        | (?<serviceInfo> eq \s+ \S+ | range \s+ \S+ \s+ \S+)
        )
        )?

        (?: \s+ (?<hasLog>log) )?
        (?: \s+ time-range \s+ (?<schName>\S+) )?
        (?: \s+ (?<isDisable>inactive) )?
        \s*/ox
    )
  {
    my $aclName       = $+{aclName};
    my $fromZone      = $self->{aclZone}{$aclName} if defined $self->{aclZone}{$aclName};
    my $aclLineNumber = $self->aclLineNumbers->{$aclName};
    my $isDisable     = 'enable';
    if ( defined $+{isDisable} and $+{isDisable} eq 'inactive' ) {
      $isDisable = 'disable';
    }

    my $rule = Firewall::Config::Element::Rule::Asa->new(
      fwId          => $self->fwId,
      zone          => $aclName,
      aclName       => $aclName,
      aclLineNumber => $aclLineNumber,
      action        => $+{action},
      schName       => $+{schName},
      hasLog        => $+{hasLog},
      content       => $string,
      isDisable     => $isDisable
    );
    my ( $protocolInfo, $srcAddressInfo, $dstAddressInfo, $serviceInfo )
      = ( $+{protocolInfo}, $+{srcAddressInfo}, $+{dstAddressInfo}, $+{serviceInfo} );
    my $protocolObjType
      = ( defined $+{protocolObjType} and $+{protocolObjType} eq 'object-group' ) ? 'protocolGroup' : 'protocol';

    if ( defined $+{schName} ) {
      if ( my $schedule = $self->getSchedule( $+{schName} ) ) {
        $rule->setSchedule($schedule);
      }
      else {
        $self->warn("schName $+{schName} 不是 schedule\n");
      }
    }
    $rule->{fromZone} = $fromZone if defined $fromZone;
    $self->addElement($rule);
    my $index = $aclName;
    push @{$self->{ruleIndex}{$index}}, $rule;
    $self->parseRuleProtocol( $rule, $protocolInfo, $protocolObjType );
    $self->parseRuleSrcAddress( $rule, $srcAddressInfo );
    $self->parseRuleDstAddress( $rule, $dstAddressInfo );
    $self->parseRuleService( $rule, $serviceInfo );

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseRule

sub parseRuleProtocol {
  my ( $self, $rule, $protocolInfo, $protocolObjType ) = @_;
  my $obj = $self->getProtocolOrProtocolGroupFromProGroupMemberName( $protocolInfo, $protocolObjType );
  if ( not defined $obj ) {
    $self->warn("的 protocolInfo $protocolInfo 不是 protocolGroup\n");
  }
  $rule->addProtocolMembers( $protocolInfo, $obj );
}

sub parseRuleSrcAddress {
  my ( $self, $rule, $srcAddressInfo ) = @_;
  my $obj;
  if ( $srcAddressInfo =~ /^Any$/io ) {
    $obj = Firewall::Config::Element::Address::Asa->new(
      fwId     => $self->fwId,
      addrName => $srcAddressInfo,
      ip       => '0.0.0.0',
      mask     => '0.0.0.0'
    );
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName($srcAddressInfo) ) {
  }
  else {
    $self->warn("的 srcAddressInfo $srcAddressInfo 不是 addressGroup\n");
  }
  $rule->addSrcAddressMembers( $srcAddressInfo, $obj );
}

sub parseRuleDstAddress {
  my ( $self, $rule, $dstAddressInfo ) = @_;
  my $obj;

  if ( $dstAddressInfo =~ /^Any$/io ) {
    $obj = Firewall::Config::Element::Address::Asa->new(
      fwId     => $self->fwId,
      addrName => $dstAddressInfo,
      ip       => '0.0.0.0',
      mask     => '0.0.0.0'
    );
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName($dstAddressInfo) ) {
  }
  else {
    $self->warn("的 dstAddressInfo $dstAddressInfo 不是 addressGroup\n");
  }

  $rule->addDstAddressMembers( $dstAddressInfo, $obj );
} ## end sub parseRuleDstAddress

sub parseRuleService {
  my ( $self, $rule, $serviceInfo ) = @_;
  my $serviceGroup = Firewall::Config::Element::ServiceGroup::Asa->new(
    fwId         => $self->fwId,
    srvGroupName => $serviceInfo // '_service_'
  );

  if ( keys %{$rule->protocolGroup->protocols} ) {
    if ( $rule->protocolGroup->protocols ~~ /^ip$/io ) {
      my $srvName = 'ipany';
      my $obj     = Firewall::Config::Element::Service::Asa->new(
        fwId     => $self->fwId,
        srvName  => $srvName,
        dstPort  => '0-65535',
        protocol => 'any'
      );
      $serviceGroup->addSrvGroupMember( $srvName, $obj );
      $serviceGroup->{srvGroupName} = $srvName;
    }
    else {
      my %protocols;

      for my $protocol ( keys %{$rule->protocolGroup->protocols} ) {
        if ( $protocol =~ /^(?:tcp|udp)$/io ) {
          $protocols{lc($protocol)} = undef;
        }
        else {
          my $srvName = $protocol . '/any';
          my $obj     = Firewall::Config::Element::Service::Asa->new(
            fwId     => $self->fwId,
            srvName  => $srvName,
            dstPort  => '0-65535',
            protocol => $protocol
          );
          $serviceGroup->addSrvGroupMember( $srvName, $obj );
          $serviceGroup->{srvGroupName} = $srvName;
        }
      }

      if ( keys %protocols ) {
        my $obj;

        if ( not defined $serviceInfo ) {
          my @protocols = keys %protocols;
          $obj = Firewall::Config::Element::Service::Asa->new(
            fwId     => $self->fwId,
            srvName  => '_rule_service_info_not_defined_',
            dstPort  => '0-65535',
            protocol => shift @protocols
          );
          for (@protocols) {
            $obj->addMeta(
              fwId     => $self->fwId,
              srvName  => '_rule_service_info_not_defined_',
              dstPort  => '0-65535',
              protocol => $_
            );
          }
        }
        else {
          $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName(
            $serviceInfo,
            $serviceGroup->srvGroupName,
            keys %protocols
          );
        }

        if ( defined $obj ) {

#当rule里面有 protocol 对象时，且 serviceInfo 是一个 serviceGroup 时，要把 serviceGroup 中协议不属于 protocol 的去掉
          if ( $obj->isa('Firewall::Config::Element::ServiceGroup::Asa') ) {
            for ( keys %{$obj->dstPortRangeMap} ) {
              if ( not exists $protocols{lc($_)} ) {
                delete $obj->dstPortRangeMap->{$_};
              }
            }
          }
          $serviceGroup->addSrvGroupMember( '_rule_service_filter_by_protocol_', $obj );
        }
      } ## end if ( keys %protocols )
    } ## end else [ if ( $rule->protocolGroup...)]
  }
  else {

  }
  $rule->addServiceMembers( $serviceGroup->srvGroupName, $serviceGroup );
} ## end sub parseRuleService

__PACKAGE__->meta->make_immutable;
1;
