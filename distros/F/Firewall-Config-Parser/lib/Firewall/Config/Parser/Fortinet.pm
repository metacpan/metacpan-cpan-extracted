package Firewall::Config::Parser::Fortinet;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element 具体元素规范
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::Fortinet;
use Firewall::Config::Element::AddressGroup::Fortinet;
use Firewall::Config::Element::Service::Fortinet;
use Firewall::Config::Element::ServiceGroup::Fortinet;
use Firewall::Config::Element::Schedule::Fortinet;
use Firewall::Config::Element::Rule::Fortinet;
use Firewall::Config::Element::StaticNat::Fortinet;
use Firewall::Config::Element::Route::Fortinet;
use Firewall::Config::Element::Interface::Fortinet;
use Firewall::Config::Element::Zone::Fortinet;
use Firewall::Config::Element::NatPool::Fortinet;
use Firewall::Config::Element::DynamicNat::Fortinet;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Parser::Role 觉得，直接使用其属性和方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Parser::Role';

has vdom => ( is => 'ro', default => 'root' );

sub parse {
  my $self = shift;
  $self->{ruleNum}  = 0;
  $self->{currVdom} = "root";
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isInterface($string) ) { $self->parseInterface($string) }
    elsif ( $self->isVdom($string) )      { $self->parseVdom($string) }
    elsif ( $self->isZone($string) )      { $self->parseZone($string) }
    elsif ( $self->isService($string) )   { $self->parseService($string) }
    elsif ( $self->isRoute($string) )     { $self->parseRoute($string) }
    else                                  { $self->ignoreLine }
  }
  $self->addRouteToInterface;
  $self->addZoneRange;
  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isNatPool($string) ) { $self->parseNatPool($string) }
    elsif ( $self->isNat($string) )     { $self->parseNat($string) }
    elsif ( $self->isVdom($string) )    { $self->parseVdom($string) }
    elsif ( $self->isAddress($string) ) { $self->parseAddress($string) }
    elsif ( $self->isAddressGroup($string) ) {$self->parseAddressGroup($string)}
    elsif ( $self->isServiceGroup($string) ) {$self->parseServiceGroup($string)}
    elsif ( $self->isSchedule($string) ) {$self->parseSchedule($string)}
    elsif ( $self->isRule($string) ) {$self->parseRule($string)}
    else {$self->ignoreLine}
  }
  $self->{config} = "";
}

sub isVdom {
  my ( $self, $string ) = @_;
  if ( $string =~ /config\s+vdom/i ) {
    $self->setElementType('vdom');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseVdom {
  my ( $self, $string ) = @_;
  $string = $self->nextUnParsedLine;
  if ( $string =~ /edit\s+(?<vdom>\S+)/ ) {
    $self->{currVdom} = $+{vdom};
    $self->{isvdom}   = 1;
  }
  while ( $string = $self->nextUnParsedLine ) {

    if ( $string =~ /config\s+system\s+global/i ) {
      last;
    }
    if ( $self->{currVdom} eq $self->{vdom} ) {
      last;
    }
    if ( $string =~ /config\s+vdom/i ) {
      $self->backtrackLine;
      last;
    }
  }
} ## end sub parseVdom

sub getZoneFromRoute {
  my ( $self, $ipSet ) = @_;
  for my $route ( sort { $b->mask <=> $a->mask } values %{$self->elements->route} ) {
    if ( $route->range->isContain($ipSet) ) {
      return $route->zoneName;
    }
  }
}

sub isInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+system\s+interface/i ) {
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

=example

config system interface
    edit "mgmt1"
        set vdom "root"
        set ip 192.168.1.99 255.255.255.0
        set allowaccess ping https fgfm
        set type physical
    next
    edit "mgmt2"
        set vdom "root"
        set type physical
    next
    edit "wan1"
        set vdom "root"
        set type physical
    next

=cut

sub parseInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config system interface/i ) {
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^end/ ) {
        last;
      }
      my ( $interface, $name, $ipAddress, $mask, $range );
      if ( $string =~ /edit\s+"(?<name>.+)"/i ) {
        $name                = $+{name};
        $interface           = Firewall::Config::Element::Interface::Fortinet->new( name => $name );
        $interface->{config} = $string;
        $interface->{vdom}   = 'root';                                                                 #default
        while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
          $interface->{config} .= "\n" . $string;
          if ( $string =~ /set\s+vdom\s+"(?<vdom>\S+)"/ ) {
            $interface->{vdom} = $+{vdom};

          }
          if ( $string =~ /set\s+ip\s+(?<ip>\S+)\s+(?<mask>\S+)\s*/ ) {
            my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
            $interface->{ipAddress}     = $+{ip};
            $interface->{mask}          = $maskNum;
            $interface->{interfaceType} = 'layer3';
            my $route = Firewall::Config::Element::Route::Fortinet->new(
              routeId      => 99999,
              type         => 'connected',
              network      => $+{ip},
              mask         => $maskNum,
              nextHop      => $+{ip},
              dstInterface => $name
            );
            $interface->addRoute($route);
            $self->addElement($route) if $interface->{vdom} eq $self->{vdom};
          }
          if ( $string =~ /set\s+alias\s+"(?<alias>\S+)"/ ) {
            $interface->{alias} = $+{alias};
          }

        } ## end while ( ( $string = $self...))
        $self->addElement($interface) if $interface->{vdom} eq $self->{vdom};
      } ## end if ( $string =~ /edit\s+"(?<name>.+)"/i)

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^config system interface/i)
} ## end sub parseInterface

sub addRouteToInterface {
  my $self       = shift;
  my $routeIndex = $self->elements->{route};
  for my $route ( values %{$routeIndex} ) {
    my $interface = $self->getInterface( $route->{dstInterface} );
    $route->{zoneName} = $interface->{zoneName};
    $interface->addRoute($route);
  }
}

sub addZoneRange {
  my $self = shift;
  for my $zone ( values %{$self->elements->{zone}} ) {
    for my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
  }
}

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /(config\s+router\s+static)|(config\s+router\s+policy)/i ) {
    $self->setElementType('router');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /(config\s+router\s+static)|(config\s+router\s+policy)/i ) {
    my $type;
    if ( $string =~ /config\s+router\s+(?<type>\S+)/ ) {
      $type = $+{type};
    }
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^end/ ) {
        last;
      }
      if ( $string =~ /edit\s+(?<routeId>\d+)/ ) {
        my %param;
        $param{type}   = $type;
        $param{config} = $string;
        my ( $routeId, $network, $mask, $nextHop, $srcInterface, $dstInterface, $srcIpMask, $distance, $priority );
        $param{routeId} = $+{routeId};
        while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
          $param{config} .= "\n" . $string;
          if ( $string =~ /set\s+dst\s+(?<network>\S+)\s+(?<mask>\S+)/ ) {
            $param{network} = $+{network};
            $param{mask}    = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
          }
          if ( $string =~ /set\s+gateway\s+(?<nextHop>\S+)/ ) {
            $param{nextHop} = $+{nextHop};
          }
          if ( $string =~ /set\s+device\s+"(?<dstInterface>\S+)"|set\s+output-device\s+"(?<dstInterface>\S+)"/ ) {
            $param{dstInterface} = $+{dstInterface};
            my $interface = $self->getInterface( $param{dstInterface} );
            $param{nextHop}  = $interface->ipAddress;
            $param{zoneName} = $interface->{zone} if defined $interface->{zone};

          }
          if ( $string =~ /set\s+input-device\s+"(?<srcInterface>\S+)"/ ) {
            $param{srcInterface} = $+{srcInterface};
          }
          if ( $string =~ /set\s+src\s+(?<srcIp>\S+)\s+(?<srcMask>\S+)/ ) {
            my $srcIp   = $+{srcIp};
            my $srcMask = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{srcMask} );
            $param{srcIpmask} = $srcIp . '/' . $srcMask;
          }
          if ( $string =~ /set\s+distance\s+(?<distance>\S+)/ ) {
            $param{distance} = $+{distance};
          }
          if ( $string =~ /set\s+priority\s+(?<priority>\S+)/ ) {
            $param{priority} = $+{priority};
          }
        } ## end while ( ( $string = $self...))
        $param{network} = '0.0.0.0' if not defined $param{network};
        $param{mask}    = 0         if not defined $param{mask};
        next if not defined $param{nextHop};
        my $route = Firewall::Config::Element::Route::Fortinet->new(%param);
        $self->addElement($route);
      } ## end if ( $string =~ /edit\s+(?<routeId>\d+)/)
    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /(config\s+router\s+static)|(config\s+router\s+policy)/i)
} ## end sub parseRoute

sub isZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config system zone/i ) {
    $self->setElementType('router');
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my $name = $+{name};
      my $zone
        = Firewall::Config::Element::Zone::Fortinet->new( fwId => $self->fwId, name => $name, config => $string );
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $zone->{config} .= "\n" . $string;
        if ( $string =~ /set\s+interface\s+(?<ints>.+)/ ) {
          my @ints = split( /\s+/, $+{ints} );
          for my $int (@ints) {
            $int =~ /"(?<interfaceName>\S+)"/;
            my $interface = $self->getInterface( $+{interfaceName} );
            $interface->{zoneName} = $name;
            $zone->addInterface($interface) unless defined $zone->interfaces->{$interface->sign};
          }
        }

      }
      $self->addElement($zone);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)
} ## end sub parseZone

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+address/i ) {
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my $name   = $+{name};
      my $config = $string;
      my ( $address, $type, $ip, $mask, $startIp, $endIp, $zone );
      $type = 'subnet';
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $config .= "\n" . $string;
        if ( $string =~ /set\s+subnet\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
          $ip   = $+{ip};
          $mask = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        }
        if ( $string =~ /set\s+type\s+(?<type>\S+)/i ) {
          $type = $+{type};
        }
        if ( $string =~ /set\s+end-ip\s+(?<ip>\S+)/ ) {
          $endIp = $+{ip};
        }
        if ( $string =~ /set\s+start-ip\s+(?<ip>\S+)/ ) {
          $startIp = $+{ip};
        }
        if ( $string =~ /set\s+associated-interface\s+"(?<zone>\S+)"/ ) {
          $zone = $+{zone};
        }
      } ## end while ( ( $string = $self...))
      if ( $type eq 'subnet' ) {
        $ip      = '0.0.0.0' if not defined $ip;
        $mask    = '0'       if not defined $mask;
        $address = Firewall::Config::Element::Address::Fortinet->new(
          addrName => $name,
          ip       => $ip,
          mask     => $mask,
          type     => $type,
          config   => $config
        );
      }
      elsif ( $type eq 'iprange' ) {
        $address = Firewall::Config::Element::Address::Fortinet->new(
          addrName => $name,
          startIp  => $startIp,
          endIp    => $endIp,
          type     => $type,
          config   => $config
        );
      }
      else {
        $address
          = Firewall::Config::Element::Address::Fortinet->new( addrName => $name, type => $type, config => $config );
      }
      $address->{zone} = $zone if defined $zone;
      $self->addElement($address);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)

} ## end sub parseAddress

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+addrgrp|config\s+firewall\s+vipgrp\s*$/ox ) {
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my $name         = $+{name};
      my $addressGroup = Firewall::Config::Element::AddressGroup::Fortinet->new( addrGroupName => $name );
      $addressGroup->{config} = $string;
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $addressGroup->{config} .= "\n" . $string;
        if ( $string =~ /set\s+member\s+(?<addrs>.+)/ ) {
          my @addrs = split( /\s/, $+{addrs} );
          for my $addr (@addrs) {
            $addr =~ /"(?<addrName>\S+)"/;
            my $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $+{addrName} );
            if ( not defined $obj ) {
              $self->warn("addrGroup $name 的 addrGroupMember $+{addrName} 既不是 address 也不是 addressGroup\n");
            }
            $addressGroup->addAddrGroupMember( $+{addrName}, $obj );
          }
        }
      }
      $self->addElement($addressGroup);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)

} ## end sub parseAddressGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $addrGroupMemberName ) = @_;
  my $obj = $self->getAddress($addrGroupMemberName) // $self->getAddressGroup($addrGroupMemberName);
  return $obj;
}

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+service\s+custom/ox ) {
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my $name   = $+{name};
      my $config = $string;
      my $service;
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $config .= "\n" . $string;
        if ( $string =~ /set (?<protocol>tcp|udp)-portrange\s+(?<ports>.+)/ ) {
          my $protocol = $+{protocol};
          my @ports    = split( /\s/, $+{ports} );
          for my $port (@ports) {
            my %params;
            $params{srvName}  = $name;
            $params{protocol} = $protocol;
            $port =~ /((?<srcPort>\S+):)?(?<dstPort>\S+)/;
            $params{dstPort} = $+{dstPort};
            $params{srcPort} = $+{srcPort} if defined $+{srcPort};
            if ( $service = $self->getService( $params{srvName} ) ) {
              $service->addMeta(%params);
              $service->{config} = $config;
            }
            else {
              $service = Firewall::Config::Element::Service::Fortinet->new(%params);
              $self->addElement($service);
              $service->{config} = $config;
            }
          }
        } ## end if ( $string =~ /set (?<protocol>tcp|udp)-portrange\s+(?<ports>.+)/)
      } ## end while ( ( $string = $self...))
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)
} ## end sub parseService

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Fortinet->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+service\s+group/ox ) {
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my $name = $+{name};
      my $serviceGroup;
      unless ( $serviceGroup = $self->getServiceGroup($name) ) {
        $serviceGroup = Firewall::Config::Element::ServiceGroup::Fortinet->new( srvGroupName => $name );
        $self->addElement($serviceGroup);
        $serviceGroup->{config} = $string;
      }
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $serviceGroup->{config} .= "\n" . $string;
        if ( $string =~ /set\s+member\s+(?<services>.+)/ ) {
          my @services = split( /\s/, $+{services} );
          for my $serName (@services) {
            $serName =~ /"(?<serName>.+)"/;
            my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{serName} );
            if ( not defined $obj ) {
              $self->warn("srvGroup $name Member $+{serName} 既不是 service 不是 pre-defined service 也不是 service Group\n");
            }
            $serviceGroup->addSrvGroupMember( $+{serName}, $obj );
          }
        }
      }
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)
} ## end sub parseServiceGroup

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;
  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName)
    // $self->getServiceGroup($srvGroupMemberName);
  return $obj;
}

sub isSchedule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+schedule/i ) {
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
  $string =~ /config\s+firewall\s+schedule\s+(?<type>\S+)/;
  my $schType = $+{type};
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my %param;
      $param{schType} = $schType;
      $param{schName} = $+{name};
      $param{config}  = $string;
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $param{config} .= "\n" . $string;
        if ( $string =~ /set\s+(?<se>\S+)\s+(?<date>\d+:\d+\s+\d+\/\d+\/\d+)/ ) {
          $param{$+{se} . 'Date'} = $+{date};
        }
        if ( $string =~ /set\s+day\s+(?<day>.+)/i ) {
          $param{day} = $+{day};
        }
        if ( $string =~ /set\s+day\s+(?<day>.+)/i ) {
          $param{day} = $+{day};
        }
        if ( $string =~ /set\s+(?<ti>\S+)\s+(?<time>\d+:\d+)/ ) {
          $param{$+{ti} . 'Time'} = $+{'time'};
        }
      }
      if ( $param{schType} eq 'recurring' ) {
        $param{endTime}   = '23:59' if not defined $param{endTime};
        $param{startTime} = '0:0'   if not defined $param{startTime};
      }
      my $schedule = Firewall::Config::Element::Schedule::Fortinet->new(%param);
      $self->addElement($schedule);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)

} ## end sub parseSchedule

sub isNatPool {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+ippool/i ) {
    $self->setElementType('natPool');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getNatPool {
  my ( $self, $name ) = @_;
  return $self->getElement( 'natPool', $name );

}

sub parseNatPool {
  my ( $self, $string ) = @_;
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my %param;
      $param{config}   = $string;
      $param{poolName} = $+{name};
      my ( $startIp, $endIp );
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $param{config} .= "\n" . $string;
        if ( $string =~ /set\s+startip\s+(?<startIp>\S+)/i ) {
          $startIp = $+{startIp};
        }
        if ( $string =~ /set\s+endip\s+(?<endIp>\S+)/i ) {
          $endIp = $+{endIp};
        }
      }
      $param{poolIp} = $startIp . '-' . $endIp;
      my $ippool = Firewall::Config::Element::NatPool::Fortinet->new(%param);
      $self->addElement($ippool);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)

} ## end sub parseNatPool

sub isNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+vip\s*$/i ) {
    $self->setElementType('nat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getNat {
  my ( $self, $name ) = @_;
  my $nat = $self->getElement( 'staticNat', $name ) // $self->getElement( 'dynamicNat', $name );
}

sub parseNat {
  my ( $self, $string ) = @_;
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+"(?<name>.+)"/ ) {
      my %param;
      $param{name}   = $+{name};
      $param{config} = $string;
      my ( $realIp, $natIp, $realPort, $natPort, $natInterface, $type, @realIp );
      my $nattype = 'stnat';
      my $proto   = 'tcp';
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $param{config} .= "\n" . $string;
        if ( $string =~ /set\s+extip\s+(?<natIp>\S+)/i ) {
          $param{natIp} = $+{natIp};
        }
        if ( $string =~ /set\s+extintf\s+"(?<natInt>.+)"/i ) {
          my $intName   = $+{natInt};
          my $interface = $self->getInterface($intName);
          $param{natInterface} = $intName;
          if ( defined $interface->{zone} ) {
            $param{natZone} = $interface->{zone};
            $param{toZone}  = $interface->{zone};
          }
          else {
            $param{natZone} = $interface->{name};
            $param{toZone}  = $interface->{name};
          }

        }
        if ( $string =~ /set\s+mappedip\s+(")?(?<realIp>\d+\.\d+[^"]+)(")?/i ) {
          $param{realIp} = $+{realIp};
          my $ip = '\d+\.\d+\.\d+\.\d+';
          my $range;
          if ( $param{realIp} =~ /$ip-$ip/ ) {
            my ( $ipmin, $ipmax ) = split( '-', $param{realIp} );
            $ipmax = $ipmin if not defined $ipmin;
            $range = Firewall::Utils::Ip->new->getRangeFromIpRange( $ipmin, $ipmax );
          }
          elsif ( $param{realIp} =~ /$ip(\/\d+)?/ ) {
            my ( $ip, $mask ) = split( '/', $param{realIp} );
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );

          }
          $param{realIpSet} = $range;
          my $realZone = $self->getZoneFromRoute($range);
          $param{realZone} = $realZone if defined $realZone;

        } ## end if ( $string =~ /set\s+mappedip\s+(")?(?<realIp>\d+\.\d+[^"]+)(")?/i)
        if ( $string =~ /set\s+portforward\s+enable/i ) {
          $nattype = 'dynat';
        }
        if ( $string =~ /set type server-load-balance/i ) {
          $nattype = 'dynat';
          $type    = 'load-balance';
        }
        if ( $string =~ /set\s+extport\s+(?<natPort>\S+)/i ) {
          $param{natDstPort} = $+{natPort};
        }
        if ( $string =~ /set\s+mappedport\s+(?<realPort>\S+)/i ) {
          $param{dstPort} = $+{realPort};
        }
        if ( $string =~ /set\s+protocol\s+(?<proto>\S+)/i ) {
          $param{proto} = $+{proto};
        }
        if ( $string =~ /config\s+realservers/i ) {
          while ( $string = $self->nextUnParsedLine ) {
            if ( $string =~ /end/i ) {
              last;
            }
            if ( $string =~ /edit\s+\d+/ ) {
              my $ip;
              my $status = 'enable';
              while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
                if ( $string =~ /set\s+ip\s+(?<ip>\S+)/ ) {
                  $ip = $+{ip};
                  $param{realIp} = $ip;
                  push @realIp, $ip;
                }
                if ( $string =~ /set\s+port\s+(?<port>\d+)/ ) {
                  $param{dstPort} = $+{port};
                }
                if ( $string =~ /set status disable/ ) {
                  $status = 'disable';
                }

              }

              #if ($status eq 'enable'){
              # $param{realIp}=$ip;
              # push @realIp,$ip;
              #}
            } ## end if ( $string =~ /edit\s+\d+/)
          } ## end while ( $string = $self->...)
        } ## end if ( $string =~ /config\s+realservers/i)
      } ## end while ( ( $string = $self...))
      my $nat;
      if ( $nattype eq 'stnat' ) {
        $nat = Firewall::Config::Element::StaticNat::Fortinet->new(%param);
      }
      else {
        $param{natDirection} = 'natDst';
        $param{srcIpRange}   = Firewall::Utils::Set->new( 0, 4294967295 );
        $param{dstIpRange}   = $param{realIpSet};
        if ( defined $type and $type eq 'load-balance' ) {
          for my $ip (@realIp) {
            $param{dstIpRange}->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask($ip) );
          }
        }
        my ( $ipmin, $ipmax ) = split( '-', $param{natIp} );
        $ipmax                = $ipmin if not defined $ipmax;
        $param{natDstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpRange( $ipmin, $ipmax );
        $nat                  = Firewall::Config::Element::DynamicNat::Fortinet->new(%param);
      }
      $self->addElement($nat);
      my ( $ipmin, $ipmax ) = split( '-', $param{natIp} );
      $ipmax = $ipmin if not defined $ipmax;
      my $vip = Firewall::Config::Element::Address::Fortinet->new(
        addrName => $param{name},
        startIp  => $ipmin,
        endIp    => $ipmax,
        type     => 'iprange'
      );
      $self->addElement($vip);
    } ## end if ( $string =~ /edit\s+"(?<name>.+)"/)
  } ## end while ( $string = $self->...)
} ## end sub parseNat

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^config\s+firewall\s+policy/i ) {
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
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string =~ /^end/ ) {
      last;
    }
    if ( $string =~ /edit\s+(?<policyId>\d+)/ ) {
      my $content = $string;
      my %param;
      $param{ruleNum}  = $self->{ruleNum}++;
      $param{policyId} = $+{policyId};
      my ( $srcf, $dstf, @src, @dst, @srv, $poolname, $natenable );
      while ( ( $string = $self->nextUnParsedLine ) !~ /next/ ) {
        $content .= "\n" . $string;
        if ( $string =~ /set\s+srcintf\s+"(?<srcintf>.+)"/i ) {
          $srcf = $+{srcintf};
          my $zone = $self->getZone($srcf);
          my $int  = $self->getInterface($srcf);
          $param{fromZone} = $srcf if defined $zone;
          $param{fromPort} = $srcf if defined $int;

        }
        if ( $string =~ /set\s+dstintf\s+"(?<dstintf>.+)"/i ) {
          $dstf = $+{dstintf};
          my $zone = $self->getZone($dstf);
          my $int  = $self->getInterface($dstf);
          $param{toZone} = $dstf if defined $zone;
          $param{toPort} = $dstf if defined $int;
        }
        if ( $string =~ /set\s+srcaddr\s+(?<addrs>.+)/i ) {
          @src = split( /(?<=")\s+/, $+{addrs} );
        }
        if ( $string =~ /set\s+dstaddr\s+(?<addrs>.+)/i ) {
          @dst = split( /(?<=")\s+/, $+{addrs} );
        }
        if ( $string =~ /set\s+action\s+(?<action>\S+)/i ) {

          #default accept
          $param{action} = $+{action};
        }
        if ( $string =~ /set\s+schedule\s+"(?<schedule>.+)"/i ) {
          if ( $+{schedule} !~ /always/ ) {
            $param{schName} = $+{schedule};
            my $schedule = $self->getSchedule( $+{schedule} );
            if ( defined $schedule ) {
              $param{schedule} = $schedule;
            }
            else {
              $self->warn("schName $+{schedule} 不是 schedule\n");
            }
          }
        }
        if ( $string =~ /set\s+service\s+(?<sers>.+)/i ) {
          @srv = split( /(?<=")\s+/, $+{sers} );
        }
        if ( $string =~ /set status disable/i ) {
          $param{isDisable} = 'disable';
        }
        if ( $string =~ /set nat enable/i ) {
          $natenable = 1;
        }
        if ( $string =~ /set\s+poolname\s+"(?<poolname>.+)"/i ) {
          $poolname = $+{poolname};
        }
      } ## end while ( ( $string = $self...))
      $param{content} = $content;
      my $rule = Firewall::Config::Element::Rule::Fortinet->new(%param);
      $self->addElement($rule);
      my $index = $srcf . $dstf;
      push @{$self->{ruleIndex}{$index}}, $rule;
      for my $src (@src) {
        $src =~ /"(?<addr>.+)"/;
        $self->addToRuleSrcAddressGroup( $rule, $+{addr} );
      }
      for my $dst (@dst) {
        $dst =~ /"(?<addr>.+)"/;
        $self->addToRuleDstAddressGroup( $rule, $+{addr} );
      }
      for my $srv (@srv) {
        $srv =~ /"(?<srv>.+)"/;
        $self->addToRuleServiceGroup( $rule, $+{srv} );
      }
      if ($natenable) {
        if ( not defined $param{isDisable} ) {
          $param{srcIpRange}   = $rule->srcAddressGroup->range;
          $param{dstIpRange}   = $rule->dstAddressGroup->range;
          $param{natDirection} = 'natSrc';
          if ( defined $poolname ) {
            my $pool = $self->getNatPool($poolname);
            $param{natSrcPool}    = $pool;
            $param{natSrcIpRange} = $pool->poolRange if defined $pool;
            my $dynat = Firewall::Config::Element::DynamicNat::Fortinet->new(%param);
            $self->addElement($dynat);
          }
          else {

=pod

  if (defined $param{toZone}){
      my $zone =  $self->getZone($param{toZone});
      for my $int (values %{$zone->{interfaces}}){
          my ($ip,$mask)=split('/',$int->ipAddress);
          $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask($ip,$mask);
          $param{natInterface}=$int->name;
          last if defined $param{natSrcIpRange};
      }
  }elsif(defined $param{toPort}){
      my $int = $self->getInterface($param{toPort});
      $param{natInterface}=$param{toPort};
      my ($ip,$mask)=split('/',$int->ipAddress);
      $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask($ip,$mask);;
  }

=cut

          }

        }

      } ## end if ($natenable)

    } ## end if ( $string =~ /edit\s+(?<policyId>\d+)/)
  } ## end while ( $string = $self->...)

} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName ) = @_;
  my $obj;
  if ( $srcAddrName =~ /^(?:Any|all)/io ) {
    unless ( $obj = $self->getAddress($srcAddrName) ) {
      $obj = Firewall::Config::Element::Address::Fortinet->new( addrName => $srcAddrName, ip => '0.0.0.0', mask => 0 );
      $self->addElement($obj);
    }
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName($srcAddrName) ) {
    $obj->{refnum} += 1;
  }
  else {
    $self->warn("的 srcAddrName $srcAddrName 不是address 也不是 addressGroup\n");
  }
  $rule->addSrcAddressMembers( $srcAddrName, $obj );
} ## end sub addToRuleSrcAddressGroup

sub addToRuleDstAddressGroup {
  my ( $self, $rule, $dstAddrName ) = @_;
  my $obj;
  if ( $dstAddrName =~ /^(?:Any|all)/io ) {
    unless ( $obj = $self->getAddress($dstAddrName) ) {
      $obj = Firewall::Config::Element::Address::Fortinet->new( addrName => $dstAddrName, ip => '0.0.0.0', mask => 0 );
      $self->addElement($obj);
    }
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName($dstAddrName) ) {
    $obj->{refnum} += 1;
  }
  else {
    $self->warn("的 dstAddrName $dstAddrName 不是address 也不是 addressGroup\n");
  }
  $rule->addDstAddressMembers( $dstAddrName, $obj );
} ## end sub addToRuleDstAddressGroup

sub addToRuleServiceGroup {
  my ( $self, $rule, $srvName ) = @_;
  my $obj;
  if ( $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($srvName) ) {
    $rule->addServiceMembers( $srvName, $obj );
    $obj->{refnum} += 1;
  }
  else {
    $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
  }
}

__PACKAGE__->meta->make_immutable;
1;
