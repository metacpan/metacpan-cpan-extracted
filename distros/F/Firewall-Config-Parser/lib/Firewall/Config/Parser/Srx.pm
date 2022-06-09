package Firewall::Config::Parser::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Srx 通用属性
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::Srx;
use Firewall::Config::Element::AddressGroup::Srx;
use Firewall::Config::Element::Service::Srx;
use Firewall::Config::Element::ServiceGroup::Srx;
use Firewall::Config::Element::Schedule::Srx;
use Firewall::Config::Element::Rule::Srx;
use Firewall::Config::Element::StaticNat::Srx;
use Firewall::Config::Element::Route::Srx;
use Firewall::Config::Element::Interface::Srx;
use Firewall::Config::Element::Zone::Srx;
use Firewall::Config::Element::NatPool::Srx;
use Firewall::Config::Element::DynamicNat::Srx;
use Firewall::DBI::Pg;
with 'Firewall::Config::Parser::Role';

sub parse {
  my $self = shift;
  $self->{ruleNum} = 1;
  while ( my $string = $self->nextUnParsedLine ) {
    if    ( $self->isRoute($string) ) { $self->parseRoute($string) }
    elsif ( $self->isInterface($string) ) {$self->parseInterface($string) }
    #elsif ($self->isActive($string)        ) { $self->setActive($string)           }
    else { $self->ignoreLine }
  }

  $self->goToHeadLine;
  while ( my $string = $self->nextUnParsedLine ) {
    if   ( $self->isZone($string) ) { $self->parseZone($string) }
    else                            { $self->ignoreLine }
  }

  $self->addRouteToInterface;
  $self->addZoneRange;

  $self->goToHeadLine;
  while ( my $string = $self->nextUnParsedLine ) {
    if    ( $self->isNatPool($string) ) { $self->parseNatPool($string) }
    elsif ( $self->isDynamicNat($string) ) {$self->parseDynamicNat($string)}
    elsif ( $self->isStaticNat($string) ) {$self->parseStaticNat($string)}
    elsif ( $self->isAddress($string) ) {$self->parseAddress($string)}
    elsif ( $self->isAddressGroup($string) ) {$self->parseAddressGroup($string)}
    elsif ( $self->isService($string) ) {$self->parseService($string)}
    elsif ( $self->isServiceGroup($string) ) {$self->parseServiceGroup($string)}
    elsif ( $self->isSchedule($string) ) {$self->parseSchedule($string)}
    else {$self->ignoreLine}
  } ## end while ( my $string = $self...)

  $self->goToHeadLine;
  while ( my $string = $self->nextUnParsedLine ) {
    if   ( $self->isRule($string) ) { $self->parseRule($string) }
    else                            { $self->ignoreLine }
  }
} ## end sub parse

sub isActive {
  my ( $self, $string ) = @_;
  if ( $string =~ /{(secondary|primary):node.+}\s*/i ) {
    return 1;
  }
  else {
    return;
  }
}

sub setActive {
  my ( $self, $string ) = @_;
  if ( $string =~ /{(\S+):node.+}\s*/i ) {
    my $active = 1;
    my $backup = 0;
    $active = 0 if lc $1 eq 'secondary';
    $backup = 1 unless $active;
    my $fwId = $self->fwId;
    my $dbi  = Firewall::DBI::Pg->new(
      host     => 'dbhost',
      port     => 5432,
      dbname   => 'firewall',
      user     => 'postgres',
      password => 'Cisc0123'
    );
    my $sqlStr = "update fw_info set active = $active where fw_id = $fwId and (active <> $active or active is null)";
    my $sqlStr1
      = "update fw_info set active = $backup where group_id = (select group_id from fw_info where fw_id = $fwId )and fw_id <> $fwId";
    eval {
      $dbi->execute($sqlStr);
      $dbi->execute($sqlStr1);
    };
    if ( !!$@ ) {
      $self->warn($@);
    }
  } ## end if ( $string =~ /{(\S+):node.+}\s*/i)
} ## end sub setActive

# set security nat source rule-set
sub isDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^(set|deactivate) \s+ security \s+ nat \s+ (source | destination) \s+ rule-set \s+/ox ) {
    $self->setElementType('dynamicNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getDynamicNat {
  my ( $self, $ruleSet, $ruleName ) = @_;
  return $self->getElement( 'dynamicNat', $ruleSet, $ruleName );
}

sub parseDynamicNat {

=example

  set security nat source rule-set dmz_untrust from zone dmz
  set security nat source rule-set dmz_untrust to zone untrust
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.34/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.37/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.38/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.39/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.40/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.41/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.46/32
  set security nat source rule-set dmz_untrust rule rule1 match source-address 172.28.40.47/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 221.176.2.123/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 221.179.195.198/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 211.136.112.109/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 211.139.144.201/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 61.145.229.29/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 211.139.144.205/32
  set security nat source rule-set dmz_untrust rule rule1 match destination-address 221.176.2.121/32
  set security nat source rule-set dmz_untrust rule rule1 then source-nat pool srcnat_pool_1

=cut

  my ( $self, $string ) = @_;
  $self->backtrackLine;
  my %params;
  my $dynamicNat;
  my $natzonestr;
  while ( $string = $self->nextUnParsedLine ) {
    if ( not $self->isDynamicNat($string) ) {
      $self->backtrackLine;
      last;
    }

    # my ($ruleSet,$staticNat);
    if (
      $string =~ /^set \s+ security \s+ nat \s+ (?<natDirection>\S+) \s+ rule-set
            \s+
            (?<ruleSet>\S+)
            \s+
            ((from \s+ zone \s+
            (?<fromZone>\S+))|(to \s+ zone \s+ (?<toZone>\S+)))
            \s*$/ox
      )
    {
      $params{fwId}         = $self->fwId;
      $params{ruleSet}      = $+{ruleSet};
      $params{natDirection} = $+{natDirection};
      $params{fromZone}     = $+{fromZone} if defined $+{fromZone};
      $params{toZone}       = $+{toZone}   if defined $+{toZone};
      $natzonestr           = $string;
    }
    else {

      if (
        $string =~ /^set \s+ security \s+ nat \s+ (?<natDirection>\S+) \s+ rule-set
                \s+
                (?<ruleSet>\S+)
                \s+
                rule
                \s+
                (?<ruleName>\S+)
                \s+
                match \s+
                ((source-address \s+ (?<srcIp>\S+))|
                (destination-address \s+ (?<dstIp>\S+))|
                (destination-port \s+ (?<dstPort>\d+)))
                \s*$/ox
        )
      {

        if ( $params{ruleSet} eq $+{ruleSet} ) {
          $params{ruleName} = $+{ruleName};
          if ( $dynamicNat = $self->getDynamicNat( $params{ruleSet}, $params{ruleName} ) ) {
            $dynamicNat->{config} .= "\n" . $string;
          }
          else {
            $params{config} = $natzonestr . "\n" . $string;
            $dynamicNat = Firewall::Config::Element::DynamicNat::Srx->new(%params);
            $self->addElement($dynamicNat);
          }

          if ( defined $+{srcIp} ) {
            my ( $ip, $mask ) = split( '/', $+{srcIp} );
            $dynamicNat->srcIpRange->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) );
          }
          if ( defined $+{dstIp} ) {
            my ( $ip, $mask ) = split( '/', $+{dstIp} );
            $dynamicNat->dstIpRange->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask ) );
          }
          if ( defined $+{dstPort} ) {
            $dynamicNat->{natDstPort} = $+{dstPort};
          }

        }
        else {
          $self->warn("$params{ruleSet},$string,需要先定义rule-set\n");
        }

        #set security nat source rule-set dmz_untrust rule rule1 then source-nat pool srcnat_pool_1
        #set security nat destination rule-set untrust_dmz rule rule5 then destination-nat pool dstnat_pool_1

      }
      elsif (
        $string =~ /^set \s+ security \s+ nat \s+ (?<natDirection>\S+) \s+ rule-set
                \s+
                (?<ruleSet>\S+)
                \s+
                rule
                \s+
                (?<ruleName>\S+)
                \s+
                then \s+
                ((source-nat \s+ pool \s+ (?<srcPool>\S+))|
                (source-nat \s+ (?<srcPool>interface))|
                (destination-nat \s+ pool \s+ (?<dstPool>\S+)))
                \s*$/ox
        )
      {
        if ( $params{ruleSet} eq $+{ruleSet} and $params{ruleName} eq $+{ruleName} ) {
          $dynamicNat = $self->getDynamicNat( $params{ruleSet}, $params{ruleName} );
          $dynamicNat->{config} .= "\n" . $string;
          if ( $+{natDirection} eq 'destination' ) {
            my $natDstPool = $self->getNatPool( $+{dstPool} );
            $dynamicNat->{natDstPool}  = $natDstPool;
            $dynamicNat->{natDstRange} = $natDstPool->poolRange;
            $dynamicNat->{toZone}      = $natDstPool->zone;
            if ( $dynamicNat->srcIpRange->length == 0 ) {
              $dynamicNat->srcIpRange->mergeToSet( 0, 4294967295 );
            }

          }
          elsif ( $+{natDirection} eq 'source' ) {
            if ( $+{srcPool} eq 'interface' ) {
              my $toZone = $self->getZone( $params{toZone} );
              if ( not defined $toZone ) {
                say $string;
              }
              $dynamicNat->{natSrcRange} = Firewall::Utils::Set->new;
              for my $interface ( values %{$toZone->interfaces} ) {
                if ( defined $interface->ipAddress ) {
                  $dynamicNat->{natSrcRange}
                    ->mergeToSet( Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->ipAddress, 32 ) );
                }
              }

            }
            else {
              my $natSrcPool = $self->getNatPool( $+{srcPool} );
              $dynamicNat->{natSrcPool}  = $natSrcPool;
              $dynamicNat->{natSrcRange} = $natSrcPool->poolRange;
            }
            if ( $dynamicNat->dstIpRange->length == 0 ) {
              $dynamicNat->dstIpRange->mergeToSet( 0, 4294967295 );
            }
            if ( $dynamicNat->srcIpRange->length == 0 ) {
              $dynamicNat->srcIpRange->mergeToSet( 0, 4294967295 );
            }

          } ## end elsif ( $+{natDirection} ...)

        }
        else {
          $self->warn("DynamicNat 定义错误!");
        }
      } ## end elsif ( $string =~ /^set \s+ security \s+ nat \s+ (?<natDirection>\S+) \s+ rule-set )
    } ## end else [ if ( $string =~ /^set \s+ security \s+ nat \s+ (?<natDirection>\S+) \s+ rule-set )]
  } ## end while ( $string = $self->...)

} ## end sub parseDynamicNat

sub isNatPool {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ security \s+ nat \s+ \S+ \s+ pool \s+/ox ) {
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
  if (
    $string =~ /^set \s+ security \s+ nat \s+
        (?<direction>\S+) \s+
        pool \s+ (?<poolName>\S+) \s+
        address \s+ ((?<minIp>\d+\.\S+) | port \s+ (?<port>\d+))
        (\s+ to \s+ (?<maxIp>\d+\.\S+))*
        \s*/ox
    )
  {
    my $natPool;
    unless ( $natPool = $self->getNatPool( $+{poolName} ) ) {
      my $poolIp = $+{minIp};
      $poolIp  = $poolIp . '-' . $+{maxIp} if defined $+{maxIp};
      $natPool = Firewall::Config::Element::NatPool::Srx->new(
        fwId         => $self->fwId,
        natDirection => $+{direction},
        poolName     => $+{poolName},
        poolIp       => $poolIp,
        config       => $string
      );
    }
    $natPool->{poolPort} = $+{port} if defined $+{port};

    if ( $+{direction} eq 'destination' ) {
      my $zone = $self->getZoneFromRoute( $natPool->poolRange );
      $natPool->{zone} = $zone;
    }
    $self->addElement($natPool);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseNatPool

sub getZoneFromRoute {
  my ( $self, $ipSet ) = @_;
  my $zone;
  for my $route ( sort { $b->mask <=> $a->mask } values %{$self->elements->route} ) {
    if ( $route->range->isContain($ipSet) ) {
      $zone = $route->zoneName;
      last;
    }
  }
  return $zone;

}

#set security zones security-zone DMZ interfaces reth2.0
sub isZone {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /^set \s+ security \s+ zones \s+ security-zone \s+ \S+ \s+ interfaces \s+ \S+ (\s+host-inbound-traffic)? \s*/ox )
  {
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

#set security zones security-zone untrust interfaces reth0.0 host-inbound-traffic system-services ping
#set security zones security-zone untrust interfaces reth0.0 host-inbound-traffic protocols all
#set security zones security-zone trust interfaces reth1.0 host-inbound-traffic system-services all
#set security zones security-zone trust interfaces reth1.0 host-inbound-traffic protocols all
#set security zones security-zone Trust host-inbound-traffic system-services all
#set security zones security-zone Trust interfaces reth0.0
sub parseZone {
  my ( $self, $string ) = @_;
  if (
    $string =~ /^set \s+ security \s+ zones \s+
        security-zone \s+ (?<name>\S+) \s+
        interfaces \s+ (?<interface>\S+)
        (\s+host-inbound-traffic)? \s*/ox
    )
  {
    my $zone;
    my $name      = $+{name};
    my $interface = $self->getInterface( $+{interface} );
    if ( not defined $interface ) {
      $self->warn("interface $+{interface} not exists");
    }
    else {

      $interface->{zoneName} = $name;
      unless ( $zone = $self->getZone($name) ) {
        $zone = Firewall::Config::Element::Zone::Srx->new(
          fwId          => $self->fwId,
          name          => $name,
          routeInstance => $interface->routeInstance,
          config        => $string
        );
      }
      $zone->addInterface($interface) unless defined $zone->interfaces->{$interface->sign};
      $self->addElement($zone);
    }

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseZone

sub isInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ interfaces \s+ \S+ \s+ unit \s+ \S+ \s+ family \s+/ox
    or $string =~ /^set \s+ routing-instances \s+ \S+ \s+ interface \s+ \S+ \s*/ox )
  {
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

  set interfaces reth0 unit 0 family inet address 10.15.254.38/29
  set interfaces reth0 unit 0 family bridge interface-mode access
  set routing-instances hadoop interface reth2.0
  set routing-instances hadoop interface reth3.0

=cut

sub parseInterface {
  my ( $self, $string ) = @_;
  if (
    $string =~ /^set \s+ interfaces \s+
        (?<name>\S+) \s+
        unit \s+ (?<unit>\S+) \s+
        family \s+ (?<family>\S+) \s+
        (?<otherContent>.*)$/ox
    )
  {
    my $name         = $+{name} . '.' . $+{unit};
    my $family       = $+{family};
    my $otherContent = $+{otherContent};
    my $interface;
    my $config = $string;
    if ( $family eq 'inet' ) {
      if ( $otherContent =~ /address \s+(?<ipAddressMask>\S+)\s*$/ox ) {
        my ( $ipAddress, $mask ) = split( '/', $+{ipAddressMask} );
        $interface = Firewall::Config::Element::Interface::Srx->new(
          fwId          => $self->fwId,
          name          => $name,
          ipAddress     => $ipAddress,
          mask          => $mask,
          interfaceType => 'layer3',
          config        => $config
        );
        my $route = Firewall::Config::Element::Route::Srx->new(
          fwId          => $self->fwId,
          network       => $ipAddress,
          mask          => $mask,
          routeInstance => 'default',
          nextHop       => $ipAddress,
          config        => $string
        );
        $interface->addRoute($route) if $mask < 31;    #排除互联地址以免影响到别的私网地址
        $self->addElement($route)    if $mask < 31;
        $self->addElement($interface);

      }
      else {
        $interface
          = Firewall::Config::Element::Interface::Srx->new( fwId => $self->fwId, name => $name, config => $string );
        $self->addElement($interface);
      }
    }
    elsif ( $family eq 'bridge' or $family eq 'ethernet-switching' ) {
      unless ( $interface = $self->getInterface($name) ) {
        $interface
          = Firewall::Config::Element::Interface::Srx->new( fwId => $self->fwId, name => $name, config => $string );
        $self->addElement($interface);
      }
      else {
        $interface->{config} .= "\n" . $string;
      }
    }

  }
  elsif (
    $string =~ /^set \s+ routing-instances \s+
        (?<routeInstance>\S+)\s+
        interface \s+ (?<name>\S+)
        \s*$/ox
    )
  {
    my $interface;
    my $name          = $+{name};
    my $routeInstance = $+{routeInstance};
    unless ( $interface = $self->getInterface($name) ) {
      $interface
        = Firewall::Config::Element::Interface::Srx->new( fwId => $self->fwId, name => $name, config => $string );
      $self->addElement($interface);
    }
    else {
      $interface->{config} .= "\n" . $string;
    }
    $interface->{routeInstance} = $routeInstance;
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseInterface

sub addRouteToInterface {
  my $self           = shift;
  my $interfaceIndex = $self->elements->{interface};
  my $routeIndex     = $self->elements->{route};

=pod
    foreach my $interface (values %{$interfaceIndex}){
        if (defined $interface->{ipAddress}){
            foreach my $route (values %{$routeIndex} ){

                    my $intset = Firewall::Utils::Ip->new->getRangeFromIpMask($interface->{ipAddress},$interface->{mask});
                    my $routset = Firewall::Utils::Ip->new->getRangeFromIpMask($route->{nextHop},32);
                    if ($intset->isContain($routset)){
                        $interface->addRoute($route);
                        $route->{zoneName} = $interface->{zoneName};
                    }

            }
        }

    }
=cut

  for my $route ( values %{$routeIndex} ) {
    if ( $route->{nextHop} =~ /[a-zA-Z]\S+/ ) {
      my $interface = $self->getInterface( $route->{nextHop} );
      $interface->addRoute($route);
      $route->{zoneName} = $interface->{zoneName};
    }
    else {
      for my $interface ( values %{$interfaceIndex} ) {
        if ( defined $interface->{ipAddress} ) {
          my $intset  = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{ipAddress}, $interface->{mask} );
          my $routset = Firewall::Utils::Ip->new->getRangeFromIpMask( $route->{nextHop},       32 );
          if ( $intset->isContain($routset) ) {
            $interface->addRoute($route);
            $route->{zoneName} = $interface->{zoneName};
          }
        }
      }

    }
  } ## end for my $route ( values ...)

} ## end sub addRouteToInterface

sub addZoneRange {
  my $self = shift;
  foreach my $zone ( values %{$self->elements->{zone}} ) {
    foreach my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
  }
}

=example

  set routing-options static route 0.0.0.0/0 next-hop 10.15.254.33
  set routing-options static route 10.57.36.0/24 next-hop 10.15.253.19
  set routing-options static route 10.57.37.0/24 next-hop 10.15.253.19
  set routing-options static route 10.57.38.0/24 next-hop 10.15.253.19
  set routing-instances hadoop routing-options static route 0.0.0.0/0 next-hop 10.15.253.1

=cut

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ (routing-instances \s+ \S+ \s+)* routing-options \s+ static \s+ route \s+/ox ) {
    $self->setElementType('router');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRoute {
  my ( $self, $network, $routeInstance ) = @_;
  $routeInstance = 'default' unless defined $routeInstance;
  return $self->getElement( 'route', $network, $routeInstance );
}

sub parseRoute {
  my ( $self, $string ) = @_;

=example

  set routing-options static route 10.57.38.0/24 next-hop 10.15.253.19
  set routing-options static route 172.17.1.239/32 next-hop gr-0/0/0.6
  set routing-instances hadoop routing-options static route 0.0.0.0/0 next-hop 10.15.253.1

=cut

  if (
    $string =~ /^set \s+
        (routing-instances \s+(?<routeInstance>\S+)\s+)?
        routing-options \s+ static \s+ route \s+
        (?<networkMask>\S+)\s+
        next-hop \s+
        (?<interface>[a-zA-Z]\S+)?
        (?<nextHop>\d+\.\d+\.\d+\.\d+)?
        \s*/ox
    )
  {
    my ( $network, $mask ) = split( '/', $+{networkMask} );
    my $routeInstance = $+{routeInstance};
    my $nextHop       = $+{nextHop};
    my $interface     = $+{interface};
    my %params;
    $params{fwId}          = $self->fwId;
    $params{network}       = $network;
    $params{mask}          = $mask;
    $params{routeInstance} = $routeInstance // 'default';
    $params{nextHop}       = $nextHop;
    $params{config}        = $string;

    if ( not defined $nextHop and defined $interface ) {
      $nextHop = $interface;
      $params{nextHop} = $nextHop;
    }
    my $route = Firewall::Config::Element::Route::Srx->new(%params);
    $self->addElement($route);
  }
  elsif (
    $string =~ /^set \s+
        (routing-instances \s+(?<routeInstance>\S+)\s+)?
        routing-options \s+ static \s+ route \s+
        (?<networkMask>\S+)\s+
        preference\s+(?<preference>\d+)
        \s*/ox
    )
  {
    #

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseRoute

sub isStaticNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^(set|deactivate) \s+ security \s+ nat \s+ static \s+/ox ) {
    $self->setElementType('staticNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getStaticNat {
  my ( $self, $ruleSet, $ruleName ) = @_;
  return $self->getElement( 'staticNat', $ruleSet, $ruleName );
}

sub parseStaticNat {

=example

  set security nat static rule-set trust_static_nat from zone trust
  set security nat static rule-set trust_static_nat rule net_10_35_204_0_22 match destination-address 10.35.204.0/22
  set security nat static rule-set trust_static_nat rule net_10_35_204_0_22 then static-nat prefix 172.28.16.0/22
  set security nat static rule-set trust_static_nat rule net_10_35_208_0_22 match destination-address 10.35.208.0/22
  set security nat static rule-set trust_static_nat rule net_10_35_208_0_22 then static-nat prefix 172.28.20.0/22

=cut

  my ( $self, $string ) = @_;
  $self->backtrackLine;
  my %params;
  my $natzonestr;
  while ( $string = $self->nextUnParsedLine ) {
    if ( not $self->isStaticNat($string) ) {
      $self->backtrackLine;
      last;
    }

    # my ($ruleSet,$staticNat);
    if (
      $string =~ /^set \s+ security \s+ nat \s+ static \s+ rule-set
            \s+
            (?<ruleSet>\S+)
            \s+
            from \s+
            (zone \s+(?<natZone>\S+))?
            (interface\s+(?<interface>\S+))?
            \s*$/ox
      )
    {
      $params{ruleSet} = $+{ruleSet};
      $params{natZone} = $+{natZone} if defined $+{natZone};
      $natzonestr      = $string;
      if ( defined $+{interface} ) {
        my $interface = $self->getInterface( $+{interface} );
        $params{natZone} = $interface->{zoneName};
      }
    }
    else {
      if (
        $string =~ /^set \s+ security \s+ nat \s+ static \s+ rule-set
                \s+
                (?<ruleSet>\S+)
                \s+
                rule
                \s+
                (?<ruleName>\S+)
                \s+
                match \s+ destination-address
                \s+
                (?<natIp>\S+)
                \s*$/ox
        )
      {
        if ( $params{ruleSet} eq $+{ruleSet} ) {
          $params{ruleName} = $+{ruleName};
          $params{natIp}    = $+{natIp};
          my ( $ip, $mask ) = split( '/', $+{natIp} );
          $params{natIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          $params{config}     = $natzonestr . "\n" . $string;

        }
        else {
          $self->warn("$params{ruleSet},$string,需要先定义rule-set\n");

        }
      }
      elsif (
        $string =~ /^set \s+ security \s+ nat \s+ static \s+ rule-set
                \s+
                (?<ruleSet>\S+)
                \s+
                rule
                \s+
                (?<ruleName>\S+)
                \s+
                then \s+ static-nat \s+ prefix
                \s+
                (?<realIp>\S+)
                \s*$/ox
        )
      {
        if ( $params{ruleSet} eq $+{ruleSet} and $params{ruleName} eq $+{ruleName} ) {
          $params{realIp} = $+{realIp};
          my ( $ip, $mask ) = split( '/', $+{realIp} );
          $params{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
          $params{realZone}    = $self->getZoneFromRoute( $params{realIpRange} );
          $params{fwId}        = $self->fwId;
          my $staticNat = Firewall::Config::Element::StaticNat::Srx->new(%params);
          $staticNat->{config} .= "\n" . $string;
          $self->addElement($staticNat);
        }
        else {
          $self->warn("staticNat 定义错误!\n");
        }

      }
      elsif (
        $string =~ /^deactivate \s+ security \s+ nat \s+ static \s+ rule-set
                \s+
                (?<ruleSet>\S+)
                \s+
                rule
                \s+
                (?<ruleName>\S+)\s*$/ox
        )
      {

      }
    } ## end else [ if ( $string =~ /^set \s+ security \s+ nat \s+ static \s+ rule-set )]
  } ## end while ( $string = $self->...)

} ## end sub parseStaticNat

sub getZoneFromIp {
  my ( $self, $network ) = @_;
  my ( $ip,   $mask )    = split( '/', $network );
  my $ipSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  my $result;
  for my $zone ( values %{$self->elements->{zone}} ) {
    if ( $zone->{range}->isContain($ipSet) ) {
      $result = $zone->{name};
      last;
    }
  }
  return $result;
}

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /(^set \s+ security \s+ zones \s+ security-zone \s+ \S+ \s+ address-book \s+ address \s+)|(^set\s+security\s+address-book\s+\S+\s+address\s+)/ox
    )
  {
    $self->setElementType('address');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddress {
  my ( $self, $zone, $addrName ) = @_;
  return $self->getElement( 'address', $zone, $addrName );
}

sub parseAddress {
  my ( $self, $string ) = @_;

=example

  set security zones security-zone l2-untrust address-book address host_10.11.104.45 10.11.104.45/32

=cut

  if (
    $string =~ /^set \s+ security \s+ zones \s+ security-zone
        \s+
        (?<zone>\S+)
        \s+
        address-book
        \s+
        address
        \s+
        (?<addrName>\S+)
        \s+
        (?<ip>\d+\.\d+\.\d+\.\d+)
        \/
        (?<mask>\d+)
        \s*$/ox
    )
  {
    my $address = Firewall::Config::Element::Address::Srx->new(
      fwId     => $self->fwId,
      addrName => $+{addrName},
      zone     => $+{zone},
      ip       => $+{ip},
      mask     => $+{mask},
      config   => $string
    );
    $self->addElement($address);
  }
  elsif (
    $string =~ /^set \s+ security
        \s+
        address-book
        \s+
        (?<zone>\S+)
        \s+
        address
        \s+
        (?<addrName>\S+)
        \s+
        (?<ip>\d+\.\d+\.\d+\.\d+)
        \/
        (?<mask>\d+)
        \s*$/ox
    )
  {
    my $address = Firewall::Config::Element::Address::Srx->new(
      fwId     => $self->fwId,
      addrName => $+{addrName},
      zone     => $+{zone},
      ip       => $+{ip},
      mask     => $+{mask},
      config   => $string
    );
    $self->addElement($address);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseAddress

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /(^set\s+security\s+zones\s+security-zone\s+\S+\s+ address-book \s+ address-set \s+)|(set\s+security\s+address-book\s+\S+\s+address-set)/ox
    )
  {
    $self->setElementType('addressGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddressGroup {
  my ( $self, $zone, $addrGroupName ) = @_;
  return $self->getElement( 'addressGroup', $zone, $addrGroupName );
}

sub parseAddressGroup {
  my ( $self, $string ) = @_;

=example

  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.104.45
  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.106.11
  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.110
  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.126
  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.18
  set security zones security-zone l2-untrust address-book address-set g_backup_client address host_10.11.77.19
  set security zones security-zone Trust address-book address-set G_Dev_Terminal_Svr address-set G_Dev_Terminal_new

=cut

  if (
    $string =~ /(^set \s+ security \s+ zones \s+ security-zone
        \s+
        (?<zone>\S+)
        \s+
        address-book
        \s+
        address-set
        \s+
        (?<addrGroupName>\S+)
        \s+
        (address|address-set)
        \s+
        (?<addrGroupMemberName>\S+)
        \s*$)|(^set \s+ security
        \s+
        address-book
        \s+
        (?<zone>\S+)
        \s+
        address-set
        \s+
        (?<addrGroupName>\S+)
        \s+
        address
        \s+
        (?<addrGroupMemberName>\S+)
        \s*$)/ox
    )
  {
    my $addressGroup;
    unless ( $addressGroup = $self->getAddressGroup( $+{zone}, $+{addrGroupName} ) ) {
      $addressGroup = Firewall::Config::Element::AddressGroup::Srx->new(
        fwId          => $self->fwId,
        addrGroupName => $+{addrGroupName},
        zone          => $+{zone},
        config        => $string
      );
      $self->addElement($addressGroup);
    }

    my $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $+{zone}, $+{addrGroupMemberName} );
    if ( not defined $obj ) {
      $self->warn(
        "addrGroup $+{addrGroupName} 的 addrGroupMember $+{addrGroupMemberName} 既不是 address 也不是 addressGroup\n");
    }
    $obj->{refnum} += 1;
    $addressGroup->addAddrGroupMember( $+{addrGroupMemberName}, $obj );

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseAddressGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $zone, $addrGroupMemberName ) = @_;
  my $obj = $self->getAddress( $zone, $addrGroupMemberName ) // $self->getAddressGroup( $zone, $addrGroupMemberName );
  $obj = $self->getAddress( 'global', $addrGroupMemberName ) // $self->getAddressGroup( 'global', $addrGroupMemberName )
    if not defined $obj;
  return $obj;
}

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ applications \s+ application \s+/ox ) {
    $self->setElementType('service');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getService {
  my ( $self, $srvName ) = @_;
  return $self->getElement( 'service', $srvName );
}

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Srx->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub parseService {
  my ( $self, $string ) = @_;

=example

  set applications application TCP_UDP_135 term TCP_UDP_135 protocol tcp
  set applications application TCP_UDP_135 term TCP_UDP_135 source-port 0-65535
  set applications application TCP_UDP_135 term TCP_UDP_135 destination-port 135-135
  set applications application TCP_UDP_135 term TCP_UDP_135_1 protocol udp
  set applications application TCP_UDP_135 term TCP_UDP_135_1 source-port 0-65535
  set applications application TCP_UDP_135 term TCP_UDP_135_1 destination-port 135-135
  set applications application S_Backup_LongTime_2 term S_Backup_LongTime_2 inactivity-timeout 10800
  set applications application ms-rpc-uuid-any-tcp protocol tcp
  set applications application ms-rpc-uuid-any-tcp uuid ffffffff-ffff-ffff-ffff-ffffffffffff
  set applications application TCP_20523 protocol tcp
  set applications application TCP_20523 source-port 0-65535
  set applications application TCP_20523 destination-port 20523-20523
  set applications application tcp_2990 term tcp_2990 alg ftp

=cut

  #因为perl中的 do while实际是 while(){ do {} }，而 do {} 里面不能使用last，所以 perl 的 do while里面不能使用last，所以这里先backtrack一下，然后使用while
  $self->backtrackLine;
  my %params;
  while ( $string = $self->nextUnParsedLine ) {
    if ( not $self->isService($string) ) {
      $self->backtrackLine;
      last;
    }

    if (
      $string =~ /^set \s+ applications \s+ application
            \s+
            (?<srvName>\S+)
            (?:\s+ term \s+ (?<term>\S+) )?
            \s+
            (?<otherContent>.+?)
            \s*$/ox
      )
    {
      my ( $srvName, $term, $otherContent ) = ( $+{srvName}, $+{term}, $+{otherContent} );

      if (
        keys %params > 0
        and ($params{srvName} ne $srvName
          or defined $params{term} and not defined $term
          or not defined $params{term} and defined $term
          or ( defined $params{term} and defined $term and $params{term} ne $term ) )
        )
      {
        #new or addMeta

        if ( my $service = $self->getService( $params{srvName} ) ) {
          $service->addMeta(%params);
          $service->{config} .= "\n" . $params{config};
        }
        else {
          $service = Firewall::Config::Element::Service::Srx->new(%params);
          $self->addElement($service);
        }
        %params = ();
      } ## end if ( keys %params > 0 ...)

      if ( keys %params == 0 ) {
        %params = ( fwId => $self->fwId, srvName => $srvName, term => $term, config => $string );
      }
      else {
        $params{config} .= "\n" . $string;
      }

      if ( $otherContent =~ /^protocol \s+ (?<protocol>\S+) \s*$/ox ) {
        $params{protocol} = $+{protocol};
      }
      elsif ( $otherContent =~ /^source-port \s+ (?<srcPort>\S+) \s*$/ox ) {
        $params{srcPort} = $+{srcPort};
      }
      elsif ( $otherContent =~ /^destination-port \s+ (?<dstPort>\S+) \s*$/ox ) {
        $params{dstPort} = $+{dstPort};
      }
      elsif ( $otherContent =~ /^inactivity-timeout \s+ (?<timeout>\S+) \s*$/ox ) {
        $params{timeout} = $+{timeout};
      }
      elsif ( $otherContent =~ /^uuid \s+ (?<uuid>\S+) \s*$/ox ) {
        $params{uuid} = $+{uuid};
      }
      elsif ( $otherContent =~ /^alg \s+ ftp \s*$/ox ) {

        #暂时忽略这个
      }
      else {
        $self->warn("$string 分析不出来\n");
      }
    }
    else {
      $self->warn("$string 分析不出来\n");
    }
  } ## end while ( $string = $self->...)

  #new or addMeta

  if ( my $service = $self->getService( $params{srvName} ) ) {
    $service->addMeta(%params);
    $service->{config} .= "\n" . $params{config};
  }
  else {
    $params{config} .= "\n" . $string;
    $service = Firewall::Config::Element::Service::Srx->new(%params);
    $self->addElement($service);
  }

} ## end sub parseService

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ applications \s+ application-set \s+/ox ) {
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

=example

  set applications application-set GuiZe_1_3 application TCP_1-19
  set applications application-set GuiZe_1_3 application TCP_2050-3388
  set applications application-set GuiZe_1_3 application UDP_1-65535

=cut

  if (
    $string =~ /^set \s+ applications \s+ application-set
        \s+
        (?<srvGroupName>\S+)
        \s+
        application
        \s+
        (?<srvGroupMemberName>\S+)
        \s*$/ox
    )
  {
    my $serviceGroup;
    unless ( $serviceGroup = $self->getServiceGroup( $+{srvGroupName} ) ) {
      $serviceGroup = Firewall::Config::Element::ServiceGroup::Srx->new(
        fwId         => $self->fwId,
        srvGroupName => $+{srvGroupName},
        config       => $string
      );
      $self->addElement($serviceGroup);
    }

    my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{srvGroupMemberName} );
    if ( not defined $obj ) {
      $self->warn(
        "srvGroup $+{srvGroupName} 的 srvGroupMember $+{srvGroupMemberName} 既不是 service 不是 pre-defined service 也不是 service Group\n"
      );
    }
    else {
      $obj->{refnum} += 1;
      $serviceGroup->addSrvGroupMember( $+{srvGroupMemberName}, $obj );
    }
  }
  else {
    $self->warn("$string 但分析不出来\n");
  }
} ## end sub parseServiceGroup

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;
  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName)
    // $self->getServiceGroup($srvGroupMemberName);
  return $obj;
}

sub isSchedule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ schedulers \s+ scheduler \s+/ox ) {
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

  set schedulers scheduler S_20130924 start-date 2013-09-24.00:00 stop-date 2013-10-23.23:59
  set schedulers scheduler WIN_UPDATE daily start-time 15:00 stop-time 23:59

=cut

  if (
    $string =~ /^set \s+ schedulers \s+ scheduler
        \s+
        (?<schName>\S+)
        \s+
        start-date
        \s+
        (?<startDate>.+?)
        \s+
        stop-date
        \s+
        (?<endDate>.+?)
        \s*$/ox
    )
  {
    my $schedule = Firewall::Config::Element::Schedule::Srx->new(
      fwId      => $self->fwId,
      schName   => $+{schName},
      startDate => $+{startDate},
      endDate   => $+{endDate}
    );
    $self->addElement($schedule);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseSchedule

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^(set | deactivate) \s+ security \s+ policies \s+/ox ) {
    $self->setElementType('rule');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRule {
  my ( $self, $fromZone, $toZone, $ruleName ) = @_;
  return $self->getElement( 'rule', $fromZone, $toZone, $ruleName );
}

sub parseRule {
  my ( $self, $string ) = @_;

=example

  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match source-address net_10.0.0.0
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match source-address net_192.168.10.0
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match destination-address net_10.33.120.0/22
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match destination-address net_10.12.120.0/22
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application junos-http
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application junos-https
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 match application tcp_8080
  set security policies from-zone l2-untrust to-zone l2-trust policy 000000-07 then permit
  deactivate security policies from-zone l2-untrust to-zone l2-trust policy 000000-07
  set security policies from-zone l2-untrust to-zone l2-trust policy 40418_2 scheduler-name S_20130924
  set security policies from-zone l2-trust to-zone l2-untrust policy old-1834 then log session-init

=cut

  if (
    $string =~ /^set \s+ security \s+ policies
        \s+
        from-zone
        \s+
        (?<fromZone>\S+)
        \s+
        to-zone
        \s+
        (?<toZone>\S+)
        \s+
        policy
        \s+
        (?<ruleName>\S+)
        \s+
        (?<otherContent>.+?)
        \s*$/ox
    )
  {
    my ( $fromZone, $toZone, $ruleName, $otherContent ) = ( $+{fromZone}, $+{toZone}, $+{ruleName}, $+{otherContent} );
    my $rule;
    if ( $rule = $self->getRule( $fromZone, $toZone, $ruleName ) ) {
      $rule->addContent($string);
    }
    else {
      $rule = Firewall::Config::Element::Rule::Srx->new(
        ruleNum  => $self->{ruleNum}++,
        fwId     => $self->fwId,
        ruleName => $ruleName,
        fromZone => $+{fromZone},
        toZone   => $+{toZone},
        content  => $string
      );
      $self->addElement($rule);
      my $index = $fromZone . $toZone;
      push @{$self->{ruleIndex}{$index}}, $rule;
    }

    if ( $otherContent =~ /^match \s+ source-address \s+ (?<srcAddrName>\S+) \s*$/ox ) {
      $self->addToRuleSrcAddressGroup( $rule, $+{srcAddrName} );
    }
    elsif ( $otherContent =~ /^match \s+ destination-address \s+ (?<dstAddrName>\S+) \s*$/ox ) {
      $self->addToRuleDstAddressGroup( $rule, $+{dstAddrName} );
    }
    elsif ( $otherContent =~ /^match \s+ application \s+ (?<srvName>\S+) \s*$/ox ) {
      $self->addToRuleServiceGroup( $rule, $+{srvName} );
    }
    elsif ( $otherContent =~ /^then \s+ (?<hasLog>log\s+\S+) \s*$/ox ) {
      $rule->setHasLog( $+{hasLog} );
    }
    elsif ( $otherContent =~ /^then \s+ (?<action>\S+) \s*$/ox ) {
      $rule->setAction( $+{action} );
    }
    elsif ( $otherContent =~ /^scheduler-name \s+ (?<schName>\S+) \s*$/ox ) {
      $rule->setSchName( $+{schName} );
      if ( my $schedule = $self->getSchedule( $+{schName} ) ) {
        $rule->setSchedule($schedule);
      }
      else {
        $self->warn("schName $+{schName} 不是 schedule\n");
      }
    }
    else {
      $self->warn("$string 分析不出来\n");
    }

  }
  elsif (
    $string =~ /^(?<isDisable>deactivate) \s+ security \s+ policies
        \s+
        from-zone
        \s+
        (?<fromZone>\S+)
        \s+
        to-zone
        \s+
        (?<toZone>\S+)
        \s+
        policy
        \s+
        (?<ruleName>\S+)
        \s*$/ox
    )
  {
    my ( $isDisable, $fromZone, $toZone, $ruleName ) = ( 'disable', $+{fromZone}, $+{toZone}, $+{ruleName} );

    my $rule;
    if ( $rule = $self->getRule( $fromZone, $toZone, $ruleName ) ) {
      $rule->setIsDisable($isDisable);
      $rule->addContent($string);
    }
    else {
      $rule = Firewall::Config::Element::Rule::Srx->new(
        fwId      => $self->fwId,
        ruleName  => $ruleName,
        fromZone  => $+{fromZone},
        toZone    => $+{toZone},
        content   => $string,
        isDisable => $isDisable
      );
      $self->addElement($rule);
      my $index = $fromZone . $toZone;
      push @{$self->{ruleIndex}{$index}}, $rule;
    }

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName ) = @_;

  my $obj;
  if ( $srcAddrName =~ /^(?:Any|any-ipv4)$/io ) {
    unless ( $obj = $self->getAddress( $rule->fromZone, $srcAddrName ) ) {
      $obj = Firewall::Config::Element::Address::Srx->new(
        fwId     => $self->fwId,
        addrName => $srcAddrName,
        ip       => '0.0.0.0',
        mask     => 0,
        zone     => $rule->fromZone
      );
      $self->addElement($obj);
    }
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $rule->fromZone, $srcAddrName ) ) {
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
  if ( $dstAddrName =~ /^(?:Any|any-ipv4)$/io ) {
    unless ( $obj = $self->getAddress( $rule->toZone, $dstAddrName ) ) {
      $obj = Firewall::Config::Element::Address::Srx->new(
        fwId     => $self->fwId,
        addrName => $dstAddrName,
        ip       => '0.0.0.0',
        mask     => 0,
        zone     => $rule->toZone
      );
      $self->addElement($obj);
    }
  }
  elsif ( $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $rule->toZone, $dstAddrName ) ) {
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
    $obj->{refnum} += 1;
  }
  else {
    $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
  }

  $rule->addServiceMembers( $srvName, $obj );
}

__PACKAGE__->meta->make_immutable;
1;
