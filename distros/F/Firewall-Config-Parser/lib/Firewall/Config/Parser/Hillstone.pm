package Firewall::Config::Parser::Hillstone;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element 具体元素规范
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::Hillstone;
use Firewall::Config::Element::AddressGroup::Hillstone;
use Firewall::Config::Element::Service::Hillstone;
use Firewall::Config::Element::ServiceGroup::Hillstone;
use Firewall::Config::Element::Schedule::Hillstone;
use Firewall::Config::Element::Rule::Hillstone;
use Firewall::Config::Element::StaticNat::Hillstone;
use Firewall::Config::Element::Route::Hillstone;
use Firewall::Config::Element::Interface::Hillstone;
use Firewall::Config::Element::Zone::Hillstone;
use Firewall::Config::Element::DynamicNat::Hillstone;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Parser::Role 觉得，直接使用其属性和方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Parser::Role';
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
    elsif ( $self->isService($string) ) {
      $self->parseService($string);
    }
    elsif ( $self->isServiceGroup($string) ) {
      $self->parseServiceGroup($string);
    }
    elsif ( $self->isSchedule($string) ) {
      $self->parseSchedule($string);
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
    if    ( $self->isNat($string) )  { $self->parseNat($string) }
    elsif ( $self->isRule($string) ) { $self->parseRule($string) }
    else                             { $self->ignoreLine }
  }

  $self->{config} = "";

} ## end sub parse

sub isInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^interface\s+(\S+)/i ) {
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
  if ( $string =~ /^interface\s+(?<name>\S+)/i ) {
    my $name   = $+{name};
    my $config = $string;
    my $interface;
    if ( !( $interface = $self->getInterface($name) ) ) {
      $interface = Firewall::Config::Element::Interface::Hillstone->new( name => $name );
      $self->addElement($interface);
    }
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {
        last;
      }
      if ( $string =~ /zone\s+"(?<zoneName>\S+)"/ ) {
        $interface->{zoneName} = $+{zoneName};
        my $zone = $self->getZone( $+{zoneName} );
        $zone->addInterface($interface);
      }
      elsif ( $string =~ /ip\s+address\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
        $interface->{ipAddress}     = $+{ip};
        $interface->{mask}          = $+{mask};
        $interface->{interfaceType} = 'layer3';
        my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        my $route   = Firewall::Config::Element::Route::Hillstone->new(
          network      => $+{ip},
          mask         => $maskNum,
          dstInterface => $name,
          nextHop      => $+{ip}
        );
        $self->addElement($route);
        $interface->addRoute($route);
      }
      $config .= "\n" . $string;
      $interface->{config} = $config;

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^interface\s+(?<name>\S+)/i)
} ## end sub parseInterface

sub isZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^zone\s+"\S+"/i ) {
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
  if ( $string =~ /^zone\s+"(?<name>\S+)"/i ) {
    my $config = $string;
    my $zone;
    my $name = $+{name};
    if ( !( $zone = $self->getZone($name) ) ) {
      $zone = Firewall::Config::Element::Zone::Hillstone->new(
        name => $name,
        fwId => $self->fwId
      );
      $self->addElement($zone);
    }
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {
        last;
      }
      if ( $string =~ /^\s*vrouter\s+"?<vr>\S+"/ ) {
        $zone->{vrouter} = $+{vr};
      }
      $config .= "\n" . $string;
      $zone->{config} = $config;

    }
  } ## end if ( $string =~ /^zone\s+"(?<name>\S+)"/i)

} ## end sub parseZone

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /address\s+".+?"/i ) {
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
  if ( $string =~ /address\s+"(?<name>\S+)"/i ) {
    my $config = $string;
    my $name   = $+{name};
    my $address;
    if ( !( $address = $self->getAddress($name) ) ) {
      $address = Firewall::Config::Element::Address::Hillstone->new( addrName => $name );
      $self->addElement($address);
    }
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {

        last;
      }
      if ( $string =~ /^\s*ip\s+(?<ipmask>\S+)/ ) {

        $address->addMember( {'ipmask' => $+{ipmask}} );

      }
      elsif ( $string =~ /range\s+(?<range>(\S+)\s+(\S+))/ ) {

        $address->addMember( {'range' => $+{range}} );

      }
      elsif ( $string =~ /member\s+"(?<addName>\S+)"/ ) {

        my $addrObj = $self->getAddress( $+{addName} );
        $address->addMember( {'obj' => $addrObj} );
      }
      elsif ( $string =~ /reference-zone\s+"(?<zone>\S+)"/ ) {
        $address->{zone} = $+{zone};

      }
      elsif ( $string =~ /description/ ) {
      }
      else {
        $self->warn( "can't parse address" . $string );
      }
      $config .= "\n" . $string;

      $address->{config} = $config;
    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /address\s+"(?<name>\S+)"/i)
} ## end sub parseAddress

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /^service\s+"\S+"/ox ) {
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
  if ( $string =~ /^service\s+"(?<name>\S+)"/i ) {
    my %params;
    $params{srvName} = $+{name};
    my $config = $string;
    my $service;
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {

        last;
      }
      if ( $string =~ /(?<proto>\S+)\s+dst-port\s+(?<dstport>(\d+)\s+(\d+)?)(\s*src-port\s+(?<srcport>\d+(\s+\d+)?))?/ )
      {
        $params{protocol} = $+{proto};
        $params{dstPort}  = $+{dstport};
        $params{srcPort}  = $+{srcport};
        if ( $service = $self->getService( $params{srvName} ) ) {
          $service->addMeta(%params);
        }
        else {
          $service = Firewall::Config::Element::Service::Hillstone->new(%params);
          $self->addElement($service);
        }
      }
      elsif ( $string =~ /icmp/ ) {
        $params{protocol} = 'icmp';
        $params{dstPort}  = '1-65535';
        if ( $service = $self->getService( $params{srvName} ) ) {
          $service->addMeta(%params);
        }
        else {
          $service = Firewall::Config::Element::Service::Hillstone->new(%params);
          $self->addElement($service);
        }

      }
      elsif ( $string =~ /description/ ) {
      }
      else {
        $self->warn( "can't parse service" . $string );
      }
      $config .= "\n" . $string;
      $service->{config} = $config;
    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^service\s+"(?<name>\S+)"/i)

} ## end sub parseService

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Hillstone->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^servgroup\s+"\S+"/ox ) {
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
  if ( $string =~ /^servgroup\s+"(?<name>\S+)"/i ) {
    my $config = $string;
    my $name   = $+{name};
    my $serGroup;
    if ( !( $serGroup = $self->getServiceGroup($name) ) ) {
      $serGroup = Firewall::Config::Element::ServiceGroup::Hillstone->new( srvGroupName => $name );
      $self->addElement($serGroup);
    }
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {
        last;
      }
      if ( $string =~ /^service\s+"(?<serName>\S+)"/ ) {
        my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{serName} );
        if ( not defined $obj ) {
          $self->warn("srvGroup $name Member $+{serName} 既不是 service 不是 pre-defined service 也不是 service Group\n");
        }
        $serGroup->addSrvGroupMember( $+{serName}, $obj );
      }
      $config .= "\n" . $string;
      $serGroup->{config} = $config;
    }
  } ## end if ( $string =~ /^servgroup\s+"(?<name>\S+)"/i)
} ## end sub parseServiceGroup

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;
  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName)
    // $self->getServiceGroup($srvGroupMemberName);
  return $obj;
}

sub isSchedule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^schedule\s+"\S+"/i ) {
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
  if ( $string =~ /^schedule\s+"(?<name>\S+)"/i ) {
    my %params;
    my $config = $string;
    $params{schName} = $+{name};
    my $schedule;
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {

        last;
      }
      if ( $string =~ /absolute\s+(start\s+(?<startdate>\S+\s+\S+)\s+)?(end\s+(?<enddate>\S+\s+\S+))/ ) {
        $params{schType}   = 'onetime';
        $params{startDate} = $+{startdate} if defined $+{startdate};
        $params{endDate}   = $+{enddate};
        $schedule          = Firewall::Config::Element::Schedule::Hillstone->new(%params);
        $self->addElement($schedule);
      }
      elsif ( $string =~ /periodic\s+(?<day>\S+((\s+\S+)+?)?)\s+(?<starttime>\d+:\d+)\s+to\s+(?<endtime>\S+)/ ) {
        $params{schType}   = 'recurring';
        $params{startTime} = $+{starttime} if defined $+{starttime};
        $params{endTime}   = $+{endtime};
        $params{day}       = $+{day};
        $schedule          = Firewall::Config::Element::Schedule::Hillstone->new(%params);
        $self->addElement($schedule);
      }
      else {
        $self->warn( "can't parse schedule " . $string );
      }

      $config .= "\n" . $string;
      $schedule->{config} = $config;

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /^schedule\s+"(?<name>\S+)"/i)

} ## end sub parseSchedule

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /ip\s+route\s+(source)?/i ) {
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
  if (
    $string =~ /ip\s+route\s+(source\s+(in-interface\s+(?<srcint>\S+)\s+)?(?<srcaddr>\d+\.\d+\.\S+)?\s+)?
        ((?<network>\d+\.\d+\S+)\s+)?((?<dstint>[a-zA-Z]+\S+)\s+)?(?<nexthop>\d+\.\d+\.\S+)?/ox
    )
  {
    my %params;
    $params{config} = $string;
    if ( defined $+{srcint} or defined $+{srcaddr} ) {
      $params{type}         = 'policy';
      $params{srcInterface} = $+{srcint}  if defined $+{srcint};
      $params{srcIpmask}    = $+{srcaddr} if defined $+{srcaddr};
    }
    if ( defined $+{network} ) {
      my ( $ip, $mask ) = split( '/', $+{network} );
      $mask            = 32 if not defined $mask;
      $params{network} = $ip;
      $params{mask}    = $mask;
    }
    $params{config}       = $string;
    $params{dstInterface} = $+{dstint} if defined $+{dstint};
    $params{nextHop}      = $+{nexthop};
    my $route = Firewall::Config::Element::Route::Hillstone->new(%params);
    $self->addElement($route);
  }
  else {

    $self->warn( "can't parse route " . $string );
  }

} ## end sub parseRoute

sub isNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ip\s+vrouter\s+"\S+"/i ) {
    $self->setElementType('router');
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

sub getDynamicNat {
  my ( $self, $id, $natDirection ) = @_;
  $self->getElement( 'dynamicNat', $natDirection, $id );

}

sub parseNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /ip\s+vrouter\s+"\S+"/i ) {
    while ( $string = $self->nextUnParsedLine ) {
      if ( $string =~ /^exit/ ) {

        last;
      }
      if (
        $string =~ /bnatrule\s+id\s+(?<id>\d+)\s+virtual\s+((address-book\s+"(?<vipbook>\S+)")|ip\s+(?<vip>\S+))
                \s+real\s+((ip\s+(?<realIp>\S+))|(address-book\s+"(?<realipbook>\S+)"))/ox
        )
      {

        my %params;
        $params{config} = $string;
        $params{id}     = $+{id};
        if ( defined $+{vipbook} ) {
          my $vip = self->getAddress( $+{vipbook} );
          $params{natIp}      = $+{vipbook};
          $params{natIpRange} = $vip->range;
        }
        elsif ( defined $+{vip} ) {
          $params{natIp} = $+{vip};
          my ( $ip, $mask ) = split( '/', $+{vip} );
          my $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          $params{natIpRange} = $range;
        }
        if ( defined $+{realipbook} ) {
          my $realipbook = self->getAddress( $+{realipbook} );
          $params{realIp}     = $+{realipbook};
          $params{natIpRange} = $realipbook->range;
        }
        elsif ( defined $+{realIp} ) {
          $params{realIp} = $+{realIp};
          my ( $ip, $mask ) = split( '/', $+{realIp} );
          my $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          $params{realIpRange} = $range;
        }
        my $staticNat = Firewall::Config::Element::StaticNat::Hillstone->new(%params);
        $self->addElement($staticNat);
      }
      elsif ( $string
        =~ /snatrule\s+id\s+(?<id>\d+)\s+from\s+("(?<src>\S+)")\s+to\s+("(?<dst>\S+)")\s+(service\s+"(?<ser>\S+)"\s+)?trans-to\s+((address-book\s+"(?<natIpbook>\S+)")|(?<natIp>\d+\.\d+\S+)|(?<int>eif-ip)\s+)/ox
        )
      {
        my %params;
        $params{id}           = $+{id};
        $params{natDirection} = 'source';
        $params{config}       = $string;
        my ( $src, $dst, $ser, $natsrc, $natip, $natint )
          = ( $+{src}, $+{dst}, $+{ser}, $+{natIpbook}, $+{natIp}, $+{int} );
        if ( defined $src ) {
          my $range;
          if ( $src =~ /any/i ) {
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          }
          else {
            my $add = $self->getAddress($src);
            if ( defined $add ) {
              $range = $add->range;
            }
            else {
              my ( $ip, $mask ) = split( '/', $src );
              $mask  = 32 if not defined $mask;
              $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
            }
          }
          $params{srcIpRange} = $range;
        }

        if ( defined $dst ) {
          my $range;
          if ( $dst =~ /any/i ) {
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          }
          else {
            my $add = $self->getAddress($dst);
            if ( defined $add ) {
              $range = $add->range;
            }
            else {
              my ( $ip, $mask ) = split( '/', $dst );
              $mask  = 32 if not defined $mask;
              $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
            }
          }
          $params{dstIpRange} = $range;
        }

        if ( defined $ser and $ser !~ /any/i ) {
          my $range = $self->getServiceOrServiceGroupFromSrvGroupMemberName($ser)->range;
          $params{srvRange} = $range;
        }
        if ( defined $natsrc ) {
          my $nataddr = $self->getAddress($natsrc);
          $params{natSrcIpRange} = $nataddr->range;
        }
        elsif ( defined $natip ) {
          my ( $ip, $mask ) = split( '/', $natip );
          $mask = 32 if not defined $mask;
          my $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          $params{natSrcIpRange} = $range;
        }

        my $dynat = Firewall::Config::Element::DynamicNat::Hillstone->new(%params);
        $self->addElement($dynat);
        if ( defined $natint ) {
          $self->setNatInterfaceAddr($dynat);
        }

      }
      elsif (
        $string =~ /dnatrule\s+id\s+(?<id>\d+)\s+from\s+"(?<src>\S+)"\s+to\s+"(?<dst>\S+)"
                \s+(service\s+"(?<ser>\S+)"\s+)?trans-to\s+"(?<natdst>\S+)"\s+(port\s+(?<natPort>\d+))? /ox
        )
      {

        my %params;
        $params{id}           = $+{id};
        $params{natDirection} = 'destination';
        $params{config}       = $string;
        my ( $src, $dst, $ser, $natdst, $natport ) = ( $+{src}, $+{dst}, $+{ser}, $+{natdst}, $+{natPort} );
        if ( defined $src ) {
          my $range;
          if ( $src =~ /any/i ) {
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          }
          else {
            my $add = $self->getAddress($src);
            if ( defined $add ) {
              $range = $add->range;
            }
            else {
              my ( $ip, $mask ) = split( '/', $src );
              $mask  = 32 if not defined $mask;
              $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
            }
          }
          $params{srcIpRange} = $range;

        }

        if ( defined $dst ) {
          my $range;
          if ( $dst =~ /any/i ) {
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', 0 );
          }
          else {
            my $add = $self->getAddress($dst);
            if ( defined $add ) {
              $range = $add->range;
            }
            else {
              my ( $ip, $mask ) = split( '/', $dst );
              $mask  = 32 if not defined $mask;
              $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
            }
          }
          $params{dstIpRange} = $range;

        }

        if ( defined $ser and $ser !~ /any/i ) {
          my $range = $self->getServiceOrServiceGroupFromSrvGroupMemberName($ser)->range;
          $params{srvRange} = $range;
        }
        if ( defined $natdst ) {
          $params{natDstIp} = $natdst;
          my $nataddr = $self->getAddress($natdst);
          my $range;
          if ( defined $nataddr ) {
            $range = $nataddr->range;
          }
          else {
            my ( $ip, $mask ) = split( '/', $natdst );
            $mask  = 32 if not defined $mask;
            $range = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          }
          $params{natDstIpRange} = $range;
        }

        if ( defined $natport ) {
          $params{natDstPort} = $natport;
          my $min  = $params{srvRange}->mins->[0];
          my $mins = ( $min & 0xFF0000 ) + $natport;
          $params{natSrvRange} = Firewall::Utils::Set->new( $mins, $mins );

        }
        my $dynat = Firewall::Config::Element::DynamicNat::Hillstone->new(%params);
        $self->addElement($dynat);
      }
      elsif (
        $string =~ /ip\s+route\s+(source\s+(in-interface\s+(?<srcint>\S+)\s+)?(?<srcaddr>\S+)?\s+)?
                ((?<network>\d+\.\d+\S+)\s+)?((?<dstint>[a-zA-Z]+\S+)\s+)?(?<nexthop>\d+\.\d+\.\S+)?/ox
        )
      {
        my %params;
        $params{config} = $string;
        if ( defined $+{srcint} or defined $+{srcaddr} ) {
          $params{type}         = 'policy';
          $params{srcInterface} = $+{srcint}  if defined $+{srcint};
          $params{srcIpmask}    = $+{srcaddr} if defined $+{srcaddr};
        }
        if ( defined $+{network} ) {
          my ( $ip, $mask ) = split( '/', $+{network} );
          $mask            = 32 if not defined $mask;
          $params{network} = $ip;
          $params{mask}    = $mask;
        }
        $params{natInterface} = $+{dstint} if defined $+{dstint};
        $params{nextHop}      = $+{nexthop};
        my $route = Firewall::Config::Element::Route::Hillstone->new(%params);
        $self->addElement($route);

      }
      else {
        $self->warn( "can't parse nat " . $string );
      }

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /ip\s+vrouter\s+"\S+"/i)

} ## end sub parseNat

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
  if ( $string =~ /rule\s+id\s+\d+|policy\s+from\s+"\S+"\s+to\s+"\S+"/i ) {
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
  if ( $string =~ /policy\s+from\s+"(?<fromZone>\S+)"\s+to\s+"(?<toZone>\S+)"/oxi ) {
    my %params;
    $params{fromZone} = $+{fromZone};
    $params{toZone}   = $+{toZone};
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /exit/ ) {
        last;
      }
      if ( $string =~ /rule\s+id\s+(?<id>\d+)/i ) {
        $self->_parseRule( $string, \%params );
      }
      if ( $string =~ /policy\s+from\s+"\S+"\s+to\s+"\S+"/oxi ) {
        $self->backtrackLine;
        last;
      }

    }
  }
  elsif ( $string =~ /rule\s+id\s+\d+/ ) {

    $self->_parseRule($string);

  }
} ## end sub parseRule

sub _parseRule {
  my ( $self, $string, $param ) = @_;
  if ( $string =~ /rule\s+id\s+(?<id>\d+)/i ) {
    my %params;
    %params = %{$param} if defined $param;
    my $content = $string;
    my $config  = $string;
    $params{policyId} = $+{id};
    $params{content}  = $content;
    $params{ruleNum}  = $self->{ruleNum}++;
    my $rule = Firewall::Config::Element::Rule::Hillstone->new(%params);
    $self->addElement($rule);

    while ( $string = $self->nextUnParsedLine ) {
      $rule->addContent( $string . "\n" );
      if ( $string =~ /exit/ ) {
        last;
      }

      if ( $string =~ /action\s+(?<action>\S+)/ox ) {
        $rule->{action} = $+{action};
      }

      if ( $string =~ /src-zone\s+"(?<srczone>\S+)"/ox ) {
        $rule->{fromZone} = $+{srczone};
      }

      if ( $string =~ /dst-zone\s+"(?<dstzone>\S+)"/ox ) {
        $rule->{toZone} = $+{dstzone};
      }

      if ( $string =~ /src-addr\s+"(?<srcaddr>\S+)"/ox ) {
        $self->addToRuleSrcAddressGroup( $rule, $+{srcaddr}, "addr" );
      }

      if ( $string =~ /dst-addr\s+"(?<dstaddr>\S+)"/ox ) {
        $self->addToRuleDstAddressGroup( $rule, $+{dstaddr}, "addr" );
      }

      if ( $string =~ /service\s+"(?<srv>\S+)"/ox ) {
        $self->addToRuleServiceGroup( $rule, $+{srv} );
      }

      if ( $string =~ /schedule\s+"(?<sch>\S+)"/ox ) {
        my $schedule = $self->getSchedule( $+{sch} );
        if ( defined $schedule ) {
          $rule->setSchedule($schedule);
        }
        else {
          $self->warn("schName $+{sch} 不是 schedule\n");
        }
      }

      if ( $string =~ /src-ip\s+(?<srcip>\S+)/ox ) {

        $self->addToRuleSrcAddressGroup( $rule, $+{srcip}, "ip" );
      }

      if ( $string =~ /dst-ip\s+(?<dstip>\S+)/ox ) {

        $self->addToRuleDstAddressGroup( $rule, $+{dstip}, "ip" );
      }

      if ( $string =~ /src-range\s+(?<src>\S+\s+\S+)/ox ) {

        $self->addToRuleSrcAddressGroup( $rule, $+{src}, "range" );
      }

      if ( $string =~ /dst-range\s+(?<dst>\S+\s+\S+)/ox ) {

        $self->addToRuleDstAddressGroup( $rule, $+{dst}, "range" );
      }

      if ( $string =~ /disable/ox ) {

        $rule->{isDisable} = 'disable';
      }

    } ## end while ( $string = $self->...)
  } ## end if ( $string =~ /rule\s+id\s+(?<id>\d+)/i)
} ## end sub _parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName, $type ) = @_;
  my $name = $srcAddrName;
  my $obj;
  if ( $type eq 'addr' ) {
    if ( $srcAddrName =~ /^(?:Any|all)$/io ) {
      unless ( $obj = $self->getAddress($srcAddrName) ) {
        $obj = Firewall::Config::Element::Address::Hillstone->new( addrName => $srcAddrName );
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
    $obj = Firewall::Config::Element::Address::Hillstone->new( addrName => $srcAddrName );
    $obj->addMember( {ipmask => "$srcAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $srcAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Hillstone->new( addrName => $ipmin . '-' . $ipmax );
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
        $obj = Firewall::Config::Element::Address::Hillstone->new( addrName => $dstAddrName );
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
    $obj = Firewall::Config::Element::Address::Hillstone->new( addrName => $dstAddrName );
    $obj->addMember( {ipmask => "$dstAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $dstAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::Hillstone->new( addrName => $ipmin . '-' . $ipmax );
    $obj->addMember( {range => "$dstAddrName"} );
  }
  $rule->addDstAddressMembers( $name, $obj );
} ## end sub addToRuleDstAddressGroup

sub addToRuleServiceGroup {
  my ( $self, $rule, $srvName ) = @_;
  my $obj;
  if ( $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($srvName) ) {
    $obj->{refnum} += 1;
    $rule->addServiceMembers( $srvName, $obj );
  }
  else {
    $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
  }

}

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

sub setNatInterfaceAddr {
  my ( $self, $dynat ) = @_;
  my $interfaceName = $self->getInterfaceFromRoute( $dynat->{srcIpRange}, $dynat->{dstIpRange} );
  if ( not defined $interfaceName ) {
    return;
  }
  my $interface = $self->getInterface($interfaceName);
  $dynat->{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{ipAddress}, 32 );

}

__PACKAGE__->meta->make_immutable;
1;
