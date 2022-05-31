package Firewall::Config::Parser::Neteye;

use Moose;
use namespace::autoclean;

use Firewall::Config::Element::Address::Neteye;
use Firewall::Config::Element::AddressGroup::Neteye;
use Firewall::Config::Element::Service::Neteye;
use Firewall::Config::Element::ServiceGroup::Neteye;
use Firewall::Config::Element::Rule::Neteye;
use Firewall::Config::Element::StaticNat::Neteye;
use Firewall::Config::Element::Route::Neteye;
use Firewall::Config::Element::Interface::Neteye;
use Firewall::Config::Element::Zone::Neteye;
use Firewall::Config::Element::DynamicNat::Neteye;
use Mojo::Util qw(dumper);
with 'Firewall::Config::Parser::Role';

sub parse {
  my $self = shift;
  $self->{ruleNum} = 0;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isZone($string) ) { $self->parseZone($string) }
    elsif ( $self->isInterface($string) ) {
      $self->parseInterface($string);
    }
    elsif ( $self->isAddress($string) ) {
      $self->parseAddress($string);
    }
    elsif ( $self->isAddressGroup($string) ) {
      $self->parseAddressGroup($string);
    }
    elsif ( $self->isService($string) ) {
      $self->parseService($string);
    }
    elsif ( $self->isServiceGroup($string) ) {
      $self->parseServiceGroup($string);
    }
    elsif ( $self->isRoute($string) ) {
      $self->parseRoute($string);
    }

    #elsif ( $self->isActive($string)       ) { $self->setActive($string)         }
    else { $self->ignoreLine }
  } ## end while ( defined( my $string...))
  $self->addRouteToInterface;
  $self->addZoneRange;
  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isStaticNat($string) ) { $self->parseStaticNat($string) }
    elsif ( $self->isDynamicNat($string) ) {
      $self->parseDynamicNat($string);
    }
    elsif ( $self->isRule($string) ) {
      $self->parseRule($string);
    }
    else {
      $self->ignoreLine;
    }
  }

  $self->{config} = "";

} ## end sub parse

sub isInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^interface\s+(\S+)|vlan\s+(\d+)/i ) {
    $self->setElementType('interface');
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

sub parseInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^\s*interface\s+ethernet\s+(?<name>\S+)|^\s*vlan\s+(?<vid>\d+)/i ) {
    my $name = $+{name};
    $name = "vlan" . $+{vid} if defined $+{vid};
    my $interface;
    if ( !( $interface = $self->getInterface($name) ) ) {
      $interface = Firewall::Config::Element::Interface::Neteye->new( name => $name );
      $self->addElement($interface);
    }
    $interface->{config} = $string;
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^\s*#\s*$/ ) {
        last;
      }
      $interface->{config} .= "\n" . $string;
      if ( $string =~ /ip\s+address\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
        $interface->{ipAddress}     = $+{ip};
        $interface->{mask}          = $+{mask};
        $interface->{interfaceType} = 'layer3';
        my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        my $route   = Firewall::Config::Element::Route::Neteye->new(
          network      => $+{ip},
          mask         => $maskNum,
          dstInterface => $name,
          nextHop      => $+{ip}
        );
        $self->addElement($route);
        $interface->addRoute($route);
      }
      elsif ( $string =~ /port\s+access\s+vlan\s+(?<vlan>\d+)/ ) {
        my $vlanInt = $self->getInterface( "vlan" . $+{vlan} );
        $interface->addVlan($vlanInt) if defined $vlanInt;
      }

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^\s*interface\s+ethernet\s+(?<name>\S+)|^\s*vlan\s+(?<vid>\d+)/i)
} ## end sub parseInterface

sub isZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^zone\s+\S+/i ) {
    $self->setElementType('zone');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub getZone {
  my ( $self, $name ) = @_;
  return $self->getElement( 'zone', $name );
}

sub parseZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^zone\s+(?<name>\S+)/i ) {
    my $name = $+{name};
    my $zone;
    if ( !( $zone = $self->getZone($name) ) ) {
      $zone = Firewall::Config::Element::Zone::Neteye->new(
        name => $name,
        fwId => $self->fwId
      );
      $self->addElement($zone);
    }
    $zone->{config} = $string;
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#\s*$/ ) {
        last;
      }
      if ( $string =~ /zone\s+(?<zoneName>\S+)\s+based-layer2\s+vlan\s+(?<vid>\d+)(\s+(?<intName>\S+))?/ ) {
        my $interface = $self->getInterface( $+{intName} );
        $interface->{zoneName} = $name;
        $zone->addInterface($interface);
        $zone->{config} .= "\n" . $string;
      }
      elsif ( $string =~ /zone\s+(?<zoneName>\S+)\s+based-layer3\s+(?<intName>\S+)/ ) {
        my $interface = $self->getInterface( $+{intName} );
        $interface->{zoneName} = $name;
        $zone->addInterface($interface);
        $zone->{config} .= "\n" . $string;
      }
      if ( $string =~ /zone\s+(\S+)\s*$/ ) {
        $self->parseZone($string);

      }

    } ## end while ( defined( $string ...))
  } ## end if ( $string =~ /^zone\s+(?<name>\S+)/i)

} ## end sub parseZone

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+ipaddr\s+/i ) {
    $self->setElementType('address');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddress {
  my ( $self, $name ) = @_;
  return $self->getElement( 'address', $name );
}

sub parseAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+ipaddr\s+(?<name>\S+)\s+(?<ipList>.+)$/i ) {
    my $name = $+{name};
    my $address;
    if ( !( $address = $self->getAddress($name) ) ) {
      $address = Firewall::Config::Element::Address::Neteye->new( addrName => $name );
      $self->addElement($address);
    }
    $address->{config} = $string;
    my $ipList = $+{ipList};

    my $ip = '\d+(?:\.\d+){3}';

    if ( $ipList =~ /^\d+\.\d+\.\d+\.\d+([,-]\d+\.\d+\.\d+\.\d+)*$/ ) {
      my @ipList = split( ',', $ipList );
      for my $ipaddr (@ipList) {
        if ( $ipaddr =~ /^$ip$/ ) {
          $address->addMember( {'ipmask' => $ipaddr . '/32'} );
        }
        elsif ( $ipaddr =~ /$ip-$ip/ ) {
          $address->addMember( {'range' => $ipaddr} );
        }
      }

    }
    elsif ( $ipList =~ /subnet\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
      my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
      $address->addMember( {'ipmask' => $+{ip} . '/' . $maskNum} );

    }
    else {
      $self->warn( "can't parse address" . $string );
    }

  } ## end if ( $string =~ /object\s+ipaddr\s+(?<name>\S+)\s+(?<ipList>.+)$/i)
} ## end sub parseAddress

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+group\s+\S+\s+type\s+ipaddr/ox ) {
    $self->setElementType('serviceGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddressGroup {
  my ( $self, $srvGroupName ) = @_;
  return $self->getElement( 'serviceGroup', $srvGroupName );
}

sub parseAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+group\s+(?<name>\S+)\s+type\s+ipaddr\s+(?<addList>\S+)/oxi ) {
    my $name    = $+{name};
    my $addList = $+{addList};
    my $addressGrp;
    if ( !( $addressGrp = $self->getAddressGroup($name) ) ) {
      $addressGrp = Firewall::Config::Element::AddressGroup::Neteye->new( addrGroupName => $name );
      $self->addElement($addressGrp);
    }
    $addressGrp->{config} = $string;
    if ( defined $addList ) {
      my @addList = split( ',', $addList );
      for my $addr (@addList) {
        my $address = $self->getAddress($addr);
        $addressGrp->addAddrGroupMember( $addr, $address );
      }
    }
  }
} ## end sub parseAddressGroup

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+service\s+/ox ) {
    $self->setElementType('service');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getService {
  my ( $self, $serviceName ) = @_;
  return $self->getElement( 'service', $serviceName );
}

sub parseService {
  my ( $self, $string ) = @_;
  if (
    $string =~ /object\s+service\s+(?<name>\S+)\s+(?<proto>tcp|udp|icmp|other\s+\d+)
        (\s+(((?<srcport>\d+(-\d+)?)\s+(?<dstport>\d+(-\d+)?))|(?<any>any)))?/oxi
    )
  {
    my %params;
    $params{srvName}  = $+{name};
    $params{protocol} = $+{proto};
    $params{srcPort}  = $+{srcport};
    my $dstport = $+{dstport};
    $dstport = 0 if not defined $dstport;
    my $any = $+{any};
    $dstport = '1-65535' if defined $any;
    $params{dstPort} = $dstport;

    if ( $params{protocol} =~ /other\s+(?<protoNum>\d+)/ ) {
      $params{protocol} = $+{protoNum};
    }
    my $service = $self->getService( $params{srvName} );
    if ( not defined $service ) {
      $service = Firewall::Config::Element::Service::Neteye->new(%params);
      $self->addElement($service);
      $service->{config} = $string;
    }
    else {
      $service->addMeta(%params);
      $service->{config} .= "\n" . $string;
    }

  }
  else {
    $self->warn( "can't parse service" . $string ) if $string !~ /service\s+\S+\s+description/;
  }

} ## end sub parseService

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Neteye->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+group\s+\S+\s+type\s+service/ox ) {
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

sub parseServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /object\s+group\s+(?<name>\S+)\s+type\s+service(\s+(?<srvList>\S+))?/i ) {
    my $name    = $+{name};
    my $srvList = $+{srvList};
    my $serGroup;
    if ( !( $serGroup = $self->getServiceGroup($name) ) ) {
      $serGroup = Firewall::Config::Element::ServiceGroup::Neteye->new( srvGroupName => $name );
      $self->addElement($serGroup);
      $serGroup->{config} = $string;
    }

    if ( defined $srvList ) {
      my @srvList = split( ',', $srvList );
      for my $serName (@srvList) {
        my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($serName);
        if ( not defined $obj ) {
          $self->warn("srvGroup $name Member $+{serName} 既不是 service 不是 pre-defined service 也不是 service Group\n");
        }
        $serGroup->addSrvGroupMember( $serName, $obj );
      }
    }
  } ## end if ( $string =~ /object\s+group\s+(?<name>\S+)\s+type\s+service(\s+(?<srvList>\S+))?/i)
} ## end sub parseServiceGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $addrGroupMemberName ) = @_;
  my $obj = $self->getAddress($addrGroupMemberName) // $self->getAddressGroup($addrGroupMemberName);
  return $obj;
}

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;
  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName)
    // $self->getServiceGroup($srvGroupMemberName);
  return $obj;
}

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /route\s+\d+\.\d+\.\d+\.\d+\s+\S+|policy\s+route\s+\S+/i ) {
    $self->setElementType('route');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub parseRoute {
  my ( $self, $string ) = @_;
  if (
    $string =~ /route\s+(?<network>\d+\.\d+\S+)\s+(?<mask>\S+)
        (\s+interface\s+(?<dstint>[a-zA-Z]+\S+))?
        (\s+gateway\s+(?<nexthop>\S+))?
        (\s+(?<metric>\d+))?/ox
    )
  {
    my %params;
    $params{network}      = $+{network};
    $params{mask}         = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
    $params{dstInterface} = $+{dstint}  if defined $+{dstint};
    $params{nextHop}      = $+{nexthop} if defined $+{nexthop};
    $params{distance}     = $+{metric}  if defined $+{metric};
    $params{type}         = "static";
    my $route = Firewall::Config::Element::Route::Neteye->new(%params);
    $self->addElement($route);
    $route->{config} = $string;
  }
  elsif ( $string =~ /policy\s+route\s+(?<name>\S+)/ ) {
    my $name = $+{name};
    my %params;
    $params{type}   = 'policy';
    $params{config} = $string;
    my $ip = '\d+(?:\.\d+){3}';
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#\s*$/ ) {
        last;
      }
      $params{config} .= "\n" . $string;
      if ( $string
        =~ /matching\s+sip\s+(?:(?:(?<startIp>$ip)(?:\s+(?<endIp>$ip))?)|(?<obj>\S+)|(?:(?<ip>$ip)\s+mask\s+(?<mask>\d+)))/
        )
      {
        my $startIp = $+{startIp};
        my $endIp   = $+{endIp};
        $endIp = $startIp if not defined $endIp;
        my $objAddr = $+{obj};
        my $ip      = $+{ip};
        my $mask    = $+{mask};
        $params{srcRange} = Firewall::Utils::Ip->new->getRangeFromIpRange( $startIp, $endIp ) if defined $startIp;
        $params{srcRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask )        if defined $ip;

        if ( defined $objAddr ) {
          my $address = $self->getAddressOrAddressGroupFromAddrGroupMemberName($objAddr);
          $params{srcRange} = $address->range if defined $address;
        }
      } ## end if ( $string =~ ...)

      if (
        $string =~ /route\s+(?<network>\d+\.\d+\S+)\s+(?<mask>\S+)
                (\s+interface\s+(?<dstint>[a-zA-Z]+\S+))?
                (\s+gateway\s+(?<nexthop>\S+))?
                (\s+(?<metric>\d+))?/ox
        )
      {
        $params{network}      = $+{network};
        $params{mask}         = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        $params{dstInterface} = $+{dstint}  if defined $+{dstint};
        $params{nextHop}      = $+{nexthop} if defined $+{nexthop};
        $params{distance}     = $+{metric}  if defined $+{metric};
        $params{type}         = "static";
        my $route = Firewall::Config::Element::Route::Neteye->new(%params);
        $self->addElement($route);

      }

    } ## end while ( defined( $string ...))

  } ## end elsif ( $string =~ /policy\s+route\s+(?<name>\S+)/)
} ## end sub parseRoute

sub isStaticNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /policy\s+mip\s+\S+/i ) {
    $self->setElementType('staticNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub getStaticNat {
  my ( $self, $id ) = @_;

  my $nat = $self->getElement( 'staticNat', $id );

}

sub parseStaticNat {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /policy\s+mip\s+(?<name>\S+)\s+(?<realIp>\d+\.\d+\.\d+\.\d+)\s+(?<natIp>\S+)(\s+(?<status>enable|disable))?/i )
  {
    my %params;
    $params{config} = $string;
    $params{id}     = $+{name};
    $params{realIp} = $+{realIp};
    $params{natIp}  = $+{natIp};
    if ( defined $+{status} and $+{status} eq 'disable' ) {
      return;
    }
    $params{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $params{realIp}, 32 );
    $params{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $params{natIp},  32 );
    my $staticnat = Firewall::Config::Element::StaticNat::Neteye->new(%params);
    $self->addElement($staticnat);

    my $rule         = Firewall::Config::Element::Rule::Neteye->new( policyId => $params{id} );
    my $useMatchRule = 0;
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#\s*$/ ) {
        last;
      }
      $staticnat->{config} .= "\n" . $string;
      my $ip = '\d+\.\d+\.\d+\.\d+';
      if (
        $string =~ /policy\s+mip\s+(?<name>\S+)\s+matching\s+(?:
                (?:dip\s+((?<sip>$ip)(?:\s+(?<eip>$ip))?|object\s+(?<addr>\S+)|group\s+(?<addrg>\S+)|netmask\s+(?<net>$ip)\s+(?<mask>$ip)))
                |(?:protocol\s+(?<proto>tcp|udp)\s+port\s+(?<sport>\d+)(\s+(?<eport>\d+))?)
                |(?:protocol\s+(?<other>icmp|other\s+\d+).+)
                |(?:(?<inoutput>input-interface|output-interface)\s+(?<intName>\S+))
                )/oxi
        )
      {
        my $name      = $+{name};
        my $sip       = $+{sip};
        my $eip       = $+{eip};
        my $addr      = $+{addr};
        my $addrg     = $+{addrg};
        my $net       = $+{net};
        my $mask      = $+{mask};
        my $proto     = $+{proto};
        my $sport     = $+{sport};
        my $eport     = $+{eport};
        my $inoutput  = $+{inoutput};
        my $interface = $+{intName};
        my $other     = $+{other};

        if ( $name eq $params{id} ) {
          $useMatchRule = 1;
          if ( defined $sip ) {
            if ( defined $eip ) {
              $self->addToRuleDstAddressGroup( $rule, "$sip $eip", "range" );
            }
            else {
              $self->addToRuleDstAddressGroup( $rule, "$sip/32", "ip" );
            }
          }

          if ( defined $addr ) {
            $self->addToRuleDstAddressGroup( $rule, $addr, "addr" );
          }
          if ( defined $addrg ) {
            $self->addToRuleDstAddressGroup( $rule, $addrg, "addr" );
          }
          if ( defined $net ) {
            my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
            $self->addToRuleDstAddressGroup( $rule, "$net/$maskNum", "addr" );
          }
          if ( defined $proto ) {
            my $port = $sport;
            $port = $sport . "-" . $eport if defined $eport;
            my $name = $proto . "/" . $port;
            my $obj  = Firewall::Config::Element::Service::Neteye->new(
              srvName  => $name,
              protocol => $proto,
              dstPort  => $port
            );
            $rule->addServiceMembers( $name, $obj );

          }
          if ( defined $other ) {
            if ( $other eq 'icmp' ) {
              my $name = 'icmp';
              my $obj  = Firewall::Config::Element::Service::Neteye->new(
                srvName  => $name,
                protocol => 'icmp',
                dstPort  => '1-65535'
              );
              $rule->addServiceMembers( $name, $obj );
            }
            elsif ( $other =~ /other\s+(?<proto>\d+)/ ) {
              my $proto = $+{proto};
              my $name  = "other" . $proto;
              my $obj   = Firewall::Config::Element::Service::Neteye->new(
                srvName  => $name,
                protocol => $proto,
                dstPort  => '0'
              );
              $rule->addServiceMembers( $name, $obj );
            }
          } ## end if ( defined $other )

        }
        else {
          last;
        }

      } ## end if ( $string =~ /policy\s+mip\s+(?<name>\S+)\s+matching\s+(?: ))
    } ## end while ( defined( $string ...))
    $staticnat->{matchRule} = $rule;
  } ## end if ( $string =~ ...)
} ## end sub parseStaticNat

sub isDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /policy\s+(snat|dnat)\s+\S+/i ) {
    $self->setElementType('dynamicNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub getDynamicNat {
  my ( $self, $id, $natDirection ) = @_;
  $self->getElement( 'dynamicNat', $natDirection, $id );

}

sub parseDynamicNat {
  my ( $self, $string ) = @_;
  my $ippat = '\d+(?:\.\d+){3}';
  if (
    $string =~ /policy\s+(?<nattype>snat|dnat)\s+(?<name>\S+)\s+(?:
        (iplist\s+(?<sipList>$ippat([,-]$ippat)*?))
        |netmask\s+(?<snet>$ippat)\s+(?<smask>$ippat)
        |object\s+(?<sobj>\S+)
        |group\s+(?<sobjg>\S+)
        |(?<dip>$ippat)(?:\s+(?<proto>tcp|udp)\s+(?<dport>\d+))?
        )\s+(?:
        (interface\s+(?<natInt>\S+))
        |iplist\s+(?:(?<nipList>$ippat([,-]$ippat)*?)|netmask\s+(?<nnet>$ippat)\s+(?<nmask>$ippat))
        |(?<ndip>$ippat)(?:\s+(?<ndport>\d+))?
        )
    /ox
    )
  {
    my $natType = $+{nattype};
    my $name    = $+{name};
    my $sipList = $+{sipList};
    my $snet    = $+{snet};
    my $smask   = $+{smask};
    my $sobj    = $+{sobj};
    my $sobjg   = $+{sobjg};
    my $dip     = $+{dip};
    my $proto   = $+{proto};
    my $dport   = $+{dport};
    my $natInt  = $+{natInt};
    my $nipList = $+{nipList};
    my $nnet    = $+{nnet};
    my $nmask   = $+{nmask};
    my $ndip    = $+{ndip};
    my $ndport  = $+{ndport};
    my %params;
    $params{id}           = $name;
    $params{natDirection} = 'source'      if $natType eq 'snat';
    $params{natDirection} = 'destination' if $natType eq 'dnat';
    $params{config}       = $string;

    if ( defined $sipList ) {
      my $srcSet = Firewall::Utils::Set->new;
      my @ipList = split( ',', $sipList );
      for my $ipaddr (@ipList) {
        if ( $ipaddr =~ /(?<startIp>$ippat)-(?<endIp>$ippat)/i ) {
          $srcSet->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpRange( $+{startIp}, $+{endIp} ) );
        }
        elsif ( $ipaddr =~ /^$ippat$/ ) {
          $srcSet->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $ipaddr, 32 ) );
        }

      }
      $params{srcIpRange} = $srcSet;
    }
    if ( defined $snet ) {
      my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm($smask);
      $params{srcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $snet, $maskNum );
    }
    if ( defined $sobj ) {
      my $address = $self->getAddressOrAddressGroupFromAddrGroupMemberName($sobj);
      $params{srcIpRange} = $address->range;
    }
    if ( defined $sobjg ) {
      my $address = $self->getAddressOrAddressGroupFromAddrGroupMemberName($sobjg);
      $params{srcIpRange} = $address->range;
    }

    if ( defined $natInt ) {
      $params{natInterface} = $natInt;
      my $interface = $self->getInterface($natInt);
      $params{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, 32 );
    }

    if ( defined $dip ) {
      $params{natDstIp}      = $dip;
      $params{natDstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $dip, 32 );
    }
    if ( defined $dport ) {
      $params{proto}       = $proto;
      $params{natDstPort}  = $dport;
      $params{natSrvRange} = Firewall::Utils::Ip->new->getRangeFromService("$proto/$dport");
    }
    if ( defined $ndip ) {
      $params{dstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $ndip, 32 );

    }

    if ( defined $ndport ) {
      $params{dstPort}  = $ndport;
      $params{srvRange} = Firewall::Utils::Ip->new->getRangeFromService("$proto/$ndport");

    }

    my $dynamicNat = Firewall::Config::Element::DynamicNat::Neteye->new(%params);
    $self->addElement($dynamicNat);
    my $useMatchRule = 0;
    my $rule         = Firewall::Config::Element::Rule::Neteye->new( policyId => $params{id} );
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#\s*$/ ) {
        last;
      }
      $dynamicNat->{config} .= "\n" . $string;
      my $ip = '\d+\.\d+\.\d+\.\d+';
      if (
        $string =~ /policy\s+(?<type>snat|dnat)\s+(?<name>\S+)\s+matching\s+(?:
                (?:dip\s+((?<sip>$ip)(?:\s+(?<eip>$ip))?|object\s+(?<addr>\S+)|group\s+(?<addrg>\S+)|netmask\s+(?<net>$ip)\s+(?<mask>$ip)))
                |(?:protocol\s+(?<proto>tcp|udp)\s+port\s+(?<sport>\d+)(\s+(?<eport>\d+))?)
                |(?:protocol\s+(?<other>icmp|other\s+\d+).+)
                |(?:(?<inoutput>input-interface|output-interface)\s+(?<intName>\S+))
                )/oxi
        )
      {

        my $name      = $+{name};
        my $sip       = $+{sip};
        my $eip       = $+{eip};
        my $addr      = $+{addr};
        my $addrg     = $+{addrg};
        my $net       = $+{net};
        my $mask      = $+{mask};
        my $proto     = $+{proto};
        my $sport     = $+{sport};
        my $eport     = $+{eport};
        my $inoutput  = $+{inoutput};
        my $interface = $+{intName};
        my $other     = $+{other};

        if ( $name eq $params{id} ) {
          $useMatchRule = 1;
          if ( defined $sip ) {
            if ( defined $eip ) {
              $self->addToRuleDstAddressGroup( $rule, "$sip $eip", "range" );
            }
            else {
              $self->addToRuleDstAddressGroup( $rule, "$sip/32", "ip" );
            }
          }

          if ( defined $addr ) {
            $self->addToRuleDstAddressGroup( $rule, $addr, "addr" );
          }
          if ( defined $addrg ) {
            $self->addToRuleDstAddressGroup( $rule, $addrg, "addr" );
          }
          if ( defined $net ) {
            my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
            $self->addToRuleDstAddressGroup( $rule, "$net/$maskNum", "addr" );
          }
          if ( defined $proto ) {
            my $port = $sport;
            $port = $port . "-" . $eport if defined $eport;
            my $name = $proto . "/" . $port;
            my $obj  = Firewall::Config::Element::Service::Neteye->new(
              srvName  => $name,
              protocol => $proto,
              dstPort  => $port
            );
            $rule->addServiceMembers( $name, $obj );

          }
          if ( defined $other ) {
            if ( $other eq 'icmp' ) {
              my $name = 'icmp';
              my $obj  = Firewall::Config::Element::Service::Neteye->new(
                srvName  => $name,
                protocol => 'icmp',
                dstPort  => '1-65535'
              );
              $rule->addServiceMembers( $name, $obj );
            }
            elsif ( $other =~ /other\s+(?<proto>\d+)/ ) {
              my $proto = $+{proto};
              my $name  = "other" . $proto;
              my $obj   = Firewall::Config::Element::Service::Neteye->new(
                srvName  => $name,
                protocol => $proto,
                dstPort  => '0'
              );
              $rule->addServiceMembers( $name, $obj );
            }
          } ## end if ( defined $other )

        }
        else {
          last;
        }
      } ## end if ( $string =~ /policy\s+(?<type>snat|dnat)\s+(?<name>\S+)\s+matching\s+(?: ))

    } ## end while ( defined( $string ...))
    if ( $useMatchRule == 1 ) {
      $dynamicNat->{matchRule} = $rule;
      if ( $dynamicNat->{natDirection} eq 'source' ) {
        $dynamicNat->{dstIpRange} = $rule->dstAddressGroup->range;

      }
      else {
        $dynamicNat->{srcIpRange} = $rule->srcAddressGroup->range;
      }
    }
  } ## end if ( $string =~ /policy\s+(?<nattype>snat|dnat)\s+(?<name>\S+)\s+(?: ))
} ## end sub parseDynamicNat

sub addRouteToInterface {
  my $self       = shift;
  my $routeIndex = $self->elements->{route};
  for my $route ( values %{$routeIndex} ) {
    if ( $route->type eq 'static' ) {
      if ( defined $route->{dstInterface} ) {
        my $interface = $self->getInterface( $route->{dstInterface} );
        $route->{zoneName} = $interface->{zoneName};
        $interface->addRoute($route);
      }
      else {
        for my $interface ( values %{$self->elements->{interface}} ) {
          if ( defined $interface->{ipAddress} ) {
            my $intset = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{ipAddress}, $interface->{mask} );

            #say dumper $route if not defined $route->{nextHop};
            my $routset = Firewall::Utils::Ip->new->getRangeFromIpMask( $route->{nextHop}, 32 );
            if ( $intset->isContain($routset) ) {
              $interface->addRoute($route);
              $route->{zoneName}     = $interface->{zoneName};
              $route->{dstInterface} = $interface->{name};
            }
          }
        }

      }
    } ## end if ( $route->type eq 'static')
  } ## end for my $route ( values ...)

} ## end sub addRouteToInterface

sub addZoneRange {
  my $self = shift;
  for my $zone ( values %{$self->elements->{zone}} ) {
    for my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
  }
}

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /policy\s+access\s+\S+\s+/i ) {
    $self->setElementType('rule');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRule {
  my ( $self, $policyId ) = @_;

  my $nat = $self->getElement( 'rule', $policyId );

}

sub parseRule {
  my ( $self, $string ) = @_;
  my $ippat = '\d+(?:\.\d+){3}';
  if (
    $string =~ /policy\s+access\s+(?<id>\S+)\s+(?<srczone>\S+)\s+
        (?:(?<sipList>$ippat([,-]$ippat)*)|object\s+(?<saddr>\S+)|group\s+(?<saddrg>\S+)|(?<sany>any))
        \s+(?<dstzone>\S+)\s+
        (?:(?<dipList>$ippat([,-]$ippat)*)|object\s+(?<daddr>\S+)|group\s+(?<daddrg>\S+)|(?<dany>any))
        \s+(?:
        (?:(?<proto>tcp|udp)\s+(?<sport>\d+(-\d+)*)(\s+(?<dport>\d+(-\d+)*)))
        |(?:(?<other>icmp|(other\s+(?<protoNum>\d+)))(\s+\S+)*)
        |(?:protocol-object\s+(?<serObj>\S+))
        |(?:protocol-group\s+(?<serObjG>\S+))
        |(?<serany>any)
        )\s+
        (?<action>permit|deny)\s+(?<status>enable|disable)\s+(?<pri>\d+)
    /oxi
    )
  {
    my %params;
    my $sipList = $+{sipList};
    my $saddr   = $+{saddr};
    my $saddrg  = $+{saddrg};
    my $sany    = $+{sany};
    my $dipList = $+{dipList};
    my $daddr   = $+{daddr};
    my $daddrg  = $+{daddrg};
    my $dany    = $+{dany};
    my $proto   = $+{proto};
    my $sport   = $+{sport};
    my $dport   = $+{dport};
    my $serObj  = $+{serObj};
    my $serObjg = $+{serObjG};
    my $serAny  = $+{serany};

    if ( defined $+{other} ) {
      if ( $+{other} eq 'icmp' ) {
        $proto = 'icmp';
        $dport = '1-65535';
      }
      else {
        $proto = $+{protoNum};
        $dport = 0;
      }
    }
    $params{policyId}  = $+{id};
    $params{content}   = $string;
    $params{ruleNum}   = $+{pri};
    $params{fromZone}  = $+{srczone};
    $params{toZone}    = $+{dstzone};
    $params{action}    = $+{action};
    $params{isDisable} = $+{status};

    my $rule = Firewall::Config::Element::Rule::Neteye->new(%params);
    $self->addElement($rule);
    if ( defined $sipList ) {
      my @ipList = split( ',', $sipList );
      for my $ipaddr (@ipList) {
        if ( $ipaddr =~ /(?<startIp>$ippat)-(?<endIp>$ippat)/i ) {
          $self->addToRuleSrcAddressGroup( $rule, $ipaddr, "range" );
        }
        elsif ( $ipaddr =~ /^$ippat$/ ) {
          $self->addToRuleSrcAddressGroup( $rule, $ipaddr . "/32", "ip" );
        }
      }
    }
    if ( defined $sany ) {
      $self->addToRuleSrcAddressGroup( $rule, $sany, "addr" );
    }
    if ( defined $saddr ) {
      $self->addToRuleSrcAddressGroup( $rule, $saddr, "addr" );
    }
    if ( defined $saddrg ) {
      $self->addToRuleSrcAddressGroup( $rule, $saddrg, "addr" );
    }

    if ( defined $dipList ) {
      my @ipList = split( ',', $dipList );
      for my $ipaddr (@ipList) {
        if ( $ipaddr =~ /(?<startIp>$ippat)-(?<endIp>$ippat)/i ) {
          $self->addToRuleDstAddressGroup( $rule, $ipaddr, "range" );
        }
        elsif ( $ipaddr =~ /^$ippat$/ ) {
          $self->addToRuleDstAddressGroup( $rule, $ipaddr . "/32", "ip" );
        }
      }
    }

    if ( defined $daddr ) {
      $self->addToRuleDstAddressGroup( $rule, $daddr, "addr" );
    }
    if ( defined $saddrg ) {
      $self->addToRuleDstAddressGroup( $rule, $daddrg, "addr" );
    }
    if ( defined $dany ) {
      $self->addToRuleDstAddressGroup( $rule, $dany, "addr" );
    }
    if ( defined $proto ) {
      my $service = $proto . "/" . $dport;
      $self->addToRuleServiceGroup( $rule, $service );
    }
    if ( defined $serObj ) {
      $self->addToRuleServiceGroup( $rule, $serObj, 'obj' );
    }
    if ( defined $serObjg ) {
      $self->addToRuleServiceGroup( $rule, $serObjg, 'obj' );
    }
    if ( defined $serAny ) {
      $self->addToRuleServiceGroup( $rule, 'any', 'obj' );
    }
  }
  elsif (
    $string =~ /policy\s+access\s+(?<name>\S+)\s+(?<sd>sourceip|desip)\s+
        (?:address\s+(?<ipList>$ippat([,-]$ippat)*)|object\s+(?<addr>\S+)|group\s+(?<addrg>\S+)|(?<net>$ippat)\s+(?<mask>$ippat))
    /oxi
    )
  {
    my $name    = $+{name};
    my $sd      = $+{sd};
    my $ipList  = $+{ipList};
    my $addr    = $+{addr};
    my $addrg   = $+{addrg};
    my $net     = $+{net};
    my $mask    = $+{mask};
    my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm($mask) if defined $mask;
    my $rule    = $self->getRule($name);
    $rule->addContent($string);

    if ( defined $ipList ) {
      my @ipList = split( ',', $ipList );
      for my $ipaddr (@ipList) {
        if ( $ipaddr =~ /(?<startIp>$ippat)-(?<endIp>$ippat)/i ) {
          $self->addToRuleSrcAddressGroup( $rule, $ipaddr, "range" ) if $sd eq 'sourceip';
          $self->addToRuleDstAddressGroup( $rule, $ipaddr, "range" ) if $sd eq 'desip';
        }
        elsif ( $ipaddr =~ /^$ippat$/ ) {
          $self->addToRuleSrcAddressGroup( $rule, $ipaddr . "/32", "ip" ) if $sd eq 'sourceip';
          $self->addToRuleDstAddressGroup( $rule, $ipaddr . "/32", "ip" ) if $sd eq 'desip';
        }
      }
    }
    if ( defined $addr ) {
      $self->addToRuleDstAddressGroup( $rule, $addr, "addr" ) if $sd eq 'desip';
      $self->addToRuleSrcAddressGroup( $rule, $addr, "addr" ) if $sd eq 'sourceip';
    }
    if ( defined $addrg ) {
      $self->addToRuleDstAddressGroup( $rule, $addrg, "addr" ) if $sd eq 'desip';
      $self->addToRuleSrcAddressGroup( $rule, $addrg, "addr" ) if $sd eq 'sourceip';
    }
    if ( defined $net ) {
      $self->addToRuleSrcAddressGroup( $rule, $net . "/$maskNum", "ip" ) if $sd eq 'sourceip';
      $self->addToRuleDstAddressGroup( $rule, $net . "/$maskNum", "ip" ) if $sd eq 'desip';
    }

  }
  elsif (
    $string =~ /policy\s+access\s+(?<name>\S+)\s+protocol\s+
        (?:
        (?:(?<proto>tcp|udp)\s+(?<sport>\d+(-\d+)*)(\s+(?<dport>\d+(-\d+)*)))
        |(?:(?<other>icmp|(other\s+(?<protoNum>\d+)))(\s+\S+)*)
        |(?:protocol-object\s+(?<serObj>\S+))
        |(?:protocol-group\s+(?<serObjG>\S+))
        )/oxi
    )
  {
    my $name    = $+{name};
    my $proto   = $+{proto};
    my $sport   = $+{sport};
    my $dport   = $+{dport};
    my $serObj  = $+{serObj};
    my $serObjg = $+{serObjG};
    my $rule    = $self->getRule($name);
    $rule->addContent($string);

    if ( defined $+{other} ) {
      if ( $+{other} eq 'icmp' ) {
        $proto = 'icmp';
        $dport = '1-65535';
      }
      else {
        $proto = $+{protoNum};
        $dport = 0;
      }
    }
    if ( defined $proto ) {
      my $service = $proto . "/" . $dport;
      $self->addToRuleServiceGroup( $rule, $service );
    }
    if ( defined $serObj ) {
      $self->addToRuleServiceGroup( $rule, $serObj, 'obj' );
    }
    if ( defined $serObjg ) {
      $self->addToRuleServiceGroup( $rule, $serObjg, 'obj' );
    }
  } ## end elsif ( $string =~ /policy\s+access\s+(?<name>\S+)\s+protocol\s+ )
} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName, $type ) = @_;
  my $name = $srcAddrName;
  my $obj;
  if ( $type eq 'addr' ) {
    if ( $srcAddrName =~ /^(?:Any|all)$/io ) {
      unless ( $obj = $self->getAddress($srcAddrName) ) {
        $obj = Firewall::Config::Element::Address::Neteye->new( addrName => $srcAddrName );
        $obj->addMember( {ipmask => '0.0.0.0/0'} );
        $self->addElement($obj);
      }
    }
    elsif ( $obj = $self->getAddress($srcAddrName) ) {
      $obj->{refnum} += 1;
    }
    else {
      $self->warn("的 srcAddrName $srcAddrName 不是address 也不是 addressGroup\n");
    }
  }
  elsif ( $type eq 'ip' ) {
    $obj = Firewall::Config::Element::Address::Neteye->new( addrName => $srcAddrName );
    $obj->addMember( {ipmask => "$srcAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '-', $srcAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Neteye->new( addrName => $ipmin . '-' . $ipmax );
    $obj->addMember( {range => "$srcAddrName"} );
  }

  $rule->addSrcAddressMembers( $name, $obj );
} ## end sub addToRuleSrcAddressGroup

sub addToRuleDstAddressGroup {
  my ( $self, $rule, $dstAddrName, $type ) = @_;
  my $name = $dstAddrName;
  my $obj;
  if ( $type eq 'addr' ) {
    if ( $dstAddrName =~ /^(?:Any|all)$/io ) {
      unless ( $obj = $self->getAddress($dstAddrName) ) {
        $obj = Firewall::Config::Element::Address::Neteye->new( addrName => $dstAddrName );
        $obj->addMember( {ipmask => '0.0.0.0/0'} );
        $self->addElement($obj);
      }
    }
    elsif ( $obj = $self->getAddress($dstAddrName) ) {
      $obj->{refnum} += 1;
    }
    else {
      $self->warn("的 dstAddrName $dstAddrName 不是address 也不是 addressGroup\n");
    }

  }
  elsif ( $type eq 'ip' ) {
    $obj = Firewall::Config::Element::Address::Neteye->new( addrName => $dstAddrName );
    $obj->addMember( {ipmask => "$dstAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '-', $dstAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Neteye->new( addrName => $ipmin . '-' . $ipmax );
    $obj->addMember( {range => "$dstAddrName"} );
  }
  $rule->addDstAddressMembers( $name, $obj );
} ## end sub addToRuleDstAddressGroup

sub addToRuleServiceGroup {
  my ( $self, $rule, $srvName, $type ) = @_;
  my $obj;
  if ( defined $type and $type eq 'obj' ) {
    if ( $srvName =~ /^any$/i ) {
      $obj = Firewall::Config::Element::Service::Neteye->new(
        srvName  => 'any',
        protocol => 'any'
      );
      $rule->addServiceMembers( $srvName, $obj );
    }
    elsif ( $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($srvName) ) {
      $obj->{refnum} += 1;
      $rule->addServiceMembers( $srvName, $obj );
    }
    else {
      $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
    }
  }
  else {
    my ( $proto, $port ) = split( '/', $srvName );
    $obj = Firewall::Config::Element::Service::Neteye->new(
      srvName  => $srvName,
      protocol => $proto,
      dstPort  => $port
    );
    $rule->addServiceMembers( $srvName, $obj );

  }
} ## end sub addToRuleServiceGroup

sub getInterfaceFromRoute {
  my ( $self, $srcSet, $dstSet ) = @_;
  my $routeIndex = $self->elements->{route};
  for my $route ( grep { $_->type eq 'policy' } values %{$routeIndex} ) {
    if ( $route->srcRange->isContain($srcSet) ) {
      return $route->{dstInterface};
    }
  }
  for my $route ( sort { $b->mask <=> $a->mask } grep { $_->type eq 'static' } values %{$routeIndex} ) {
    if ( $route->range->isContain($dstSet) ) {
      return $route->dstInterface;
    }
  }
  return;

} ## end sub getInterfaceFromRoute

__PACKAGE__->meta->make_immutable;
1;
