package Firewall::Config::Parser::H3c;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Element 具体元素规范
#------------------------------------------------------------------------------
use Firewall::Config::Element::Address::H3c;
use Firewall::Config::Element::Service::H3c;
use Firewall::Config::Element::Schedule::H3c;
use Firewall::Config::Element::Rule::H3c;
use Firewall::Config::Element::StaticNat::H3c;
use Firewall::Config::Element::Route::H3c;
use Firewall::Config::Element::Interface::H3c;
use Firewall::Config::Element::Zone::H3c;
use Firewall::Config::Element::DynamicNat::H3c;
use Firewall::Config::Element::StaticNat::H3c;
use Firewall::Config::Element::NatPool::H3c;

#------------------------------------------------------------------------------
# 加载 Firewall::Config::Parser::Role 觉得，直接使用其属性和方法
#------------------------------------------------------------------------------
with 'Firewall::Config::Parser::Role';

sub parse {
  my $self = shift;
  $self->{ruleNum} = 0;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isAddress($string) )   { $self->parseAddress($string) }
    elsif ( $self->isNatPool($string) )   { $self->parseNatPool($string) }
    elsif ( $self->isService($string) )   { $self->parseService($string) }
    elsif ( $self->isPortObj($string) )   { $self->parsePortObj($string) }
    elsif ( $self->isInterface($string) ) { $self->parseInterface($string) }
    elsif ( $self->isZone($string) )      { $self->parseZone($string) }
    elsif ( $self->isSchedule($string) )  { $self->parseSchedule($string) }
    elsif ( $self->isRoute($string) )     { $self->parseRoute($string) }
    elsif ( $self->isAcl($string) )       { $self->parseAcl($string) }
    elsif ( $self->isZonePair($string) )  { $self->parseZonePair($string) }

    #elsif ( $self->isActive($string)       ) { $self->setActive($string)         }
    else { $self->ignoreLine }
  } ## end while ( defined( my $string...))
  $self->completeObj();
  $self->addRouteToInterface;
  $self->addZoneRange;
  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isStaticNat($string) )  { $self->parseStaticNat($string) }
    elsif ( $self->isDynamicNat($string) ) { $self->parseDynamicNat($string) }
    elsif ( $self->isRule($string) )       { $self->parseRule($string) }
    else                                   { $self->ignoreLine }
  }

  $self->{config} = "";

} ## end sub parse

sub completeObj {
  my $self = shift;
  for my $address ( values %{$self->{elements}{address}} ) {
    if ( defined $address->{needcomplete} ) {
      for my $addname ( @{$address->{needcomplete}} ) {
        my $addrObj = $self->getAddress($addname);
        $address->addMember( {'obj' => $addrObj} );
      }
    }
  }

  for my $service ( values %{$self->{elements}{service}} ) {
    if ( defined $service->{needcomplete} ) {
      for my $sername ( @{$service->{needcomplete}} ) {

        my $serObj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($sername);
        if ( not defined $serObj ) {
          $self->warn("not defined service $sername");
        }
        else {
          $service->addMeta($serObj);
        }
      }
    }
  }

} ## end sub completeObj

sub isZonePair {
  my ( $self, $string ) = @_;
  if ( $string =~ /zone-pair\s+security/i ) {
    $self->setElementType('zonePair');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getZonePair {
  my $self = shift;
  return $self->{zonePair};
}

sub parseZonePair {
  my ( $self, $string ) = @_;
  if ( $string =~ /zone-pair\s+security\s+source\s+(?<fromZone>\S+)\s+destination\s+(?<toZone>\S+)/i ) {
    my $fromZone = $+{fromZone};
    my $toZone   = $+{toZone};
    while ( defined( my $string = $self->nextUnParsedLine ) ) {
      last if $string =~ /^\s*#/;
      if ( $string =~ /object-policy\s+apply\s+ip\s+(?<policyName>\S+)/ ) {
        $self->{zonePair}{obj}{$+{policyName}} = {name => $+{policyName}, fromZone => $fromZone, toZone => $toZone};
      }
      elsif ( $string =~ /packet-filter\s+((?<id>\d+)|name\s+(?<name>\S+))/ ) {
        my $aclName = $+{id};
        $aclName = $+{name} if defined $+{name};
        $self->{zonePair}{acl}{$aclName} = {name => $aclName, fromZone => $fromZone, toZone => $toZone};
      }
      else {
        say "can't parser $string";
      }

    } ## end while ( defined( my $string...))

  } ## end if ( $string =~ /zone-pair\s+security\s+source\s+(?<fromZone>\S+)\s+destination\s+(?<toZone>\S+)/i)

} ## end sub parseZonePair

sub isAcl {
  my ( $self, $string ) = @_;
  if ( $string =~ /acl\s+(basic|advanced)/i ) {
    $self->setElementType('rule');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAcl {
  my ( $self, $name ) = @_;

  return $self->{ruleIndex}{$name};
}

sub parseAcl {
  my ( $self, $string ) = @_;
  my $zonePair = $self->getZonePair();
  if ( $string =~ /acl\s+basic\s+((?<id>\d+)|name\s+(?<name>\S+))\s*/i ) {
    my %param;
    my $content = $string;
    $param{ruleType} = 'acl';
    $param{aclName}  = $+{id}   if defined $+{id};
    $param{aclName}  = $+{name} if defined $+{name};
    $param{aclType}  = 'basic';
    if ( defined $zonePair->{acl}{$param{aclName}} ) {
      $param{fromZone} = $zonePair->{acl}{$param{aclName}}{fromZone};
      $param{toZone}   = $zonePair->{acl}{$param{aclName}}{toZone};
    }
    while ( defined( my $string = $self->nextUnParsedLine ) ) {
      last if $string =~ /^\s*#/;
      if ( $string
        =~ /rule\s+(?<aclRuleNum>\d+)\s+(?<action>deny|permit)(\s+vpn-instance\s+\S+)?(\s+source\s+(?<src>\S+\s+\S+|any))?(\s+time-range\s+(?<sch>\S+))?/
        )
      {
        $param{aclRuleNum} = $+{aclRuleNum};
        $param{action}     = $+{action};
        $param{schName}    = $+{sch} if defined $+{sch};
        my $src    = $+{src};
        my $config = $content;
        $config .= "\n" . $string;
        $param{content} = $config;
        my $rule = Firewall::Config::Element::Rule::H3c->new(%param);
        push @{$self->{ruleIndex}{$param{aclName}}}, $rule;
        $self->addElement($rule);

        if ( not defined $src or $src =~ /any/ ) {
          $src = 'any' if not defined $src;
          $self->addToRuleSrcAddressGroup( $rule, $src, 'addr' );
          $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' );
        }
        elsif ( $src =~ /object-group\s+(?<addrName>\S+)/ ) {
          $self->addToRuleSrcAddressGroup( $rule, $+{addrName}, 'addr' );
          $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' );

        }
        else {
          $src =~ /(?<ip>\d+\.\d+\.\d+\.\d+)\s+(?<wild>\S+)/;
          my $ip       = $+{ip};
          my $wildMask = $+{wild};
          my $mask     = $self->changeWildMaskToMaskNum($wildMask);
          $self->addToRuleSrcAddressGroup( $rule, "$ip/$mask", 'ip' );
          $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' );
        }
        my $obj = Firewall::Config::Element::Service::H3c->new( srvName => 'any', protocol => 'any' );
        $rule->addServiceMembers( 'any', $obj );

      } ## end if ( $string =~ ...)
    } ## end while ( defined( my $string...))

  }
  elsif ( $string =~ /acl\s+advanced\s+((?<id>\d+)|name\s+(?<name>\S+))\s*/i ) {
    my %param;
    my $content = $string;
    $param{ruleType} = 'acl';
    $param{aclName}  = $+{id}   if defined $+{id};
    $param{aclName}  = $+{name} if defined $+{name};
    $param{aclType}  = 'advanced';
    if ( defined $zonePair->{acl}{$param{aclName}} ) {
      $param{fromZone} = $zonePair->{acl}{$param{aclName}}{fromZone};
      $param{toZone}   = $zonePair->{acl}{$param{aclName}}{toZone};
    }
    while ( defined( my $string = $self->nextUnParsedLine ) ) {
      last if $string =~ /^\s*#/;
      if (
        $string =~ /rule\s+(?<aclRuleNum>\d+)\s+(?<action>deny|permit)\s+(?<protocol>\S+)
                (\s+source\s+(?<src>\S+\s+\S+|any))?
                (\s+destination\s+(?<dst>\S+\s+\S+|any))?
                (\s+destination-port\s+(?<opt>eq|gt|lt|range|object-group)\s+(?<port>\S+(\s+\S+)?))?
                (\s+time-range\s+(?<sch>\S+))?/ox
        )
      {
        $param{aclRuleNum} = $+{aclRuleNum};
        $param{action}     = $+{action};
        $param{schName}    = $+{sch} if defined $+{sch};
        my $src      = $+{src};
        my $dst      = $+{dst};
        my $opt      = $+{opt};
        my $protocol = $+{protocol};
        my $port     = $+{port};
        my $config   = $content;
        $config .= "\n" . $string;
        $param{content} = $config;
        my $rule = Firewall::Config::Element::Rule::H3c->new(%param);
        $self->addElement($rule);
        push @{$self->{ruleIndex}{$param{aclName}}}, $rule;

        if ( defined $src and $src =~ /any/ ) {
          $self->addToRuleSrcAddressGroup( $rule, $src, 'addr' );
        }
        elsif ( defined $src and $src =~ /object-group\s+(?<addrName>\S+)/ ) {
          $self->addToRuleSrcAddressGroup( $rule, $+{addrName}, 'addr' );
        }
        elsif ( defined $src and $src =~ /(?<ip>\d+\.\d+\.\d+\.\d+)\s+(?<wild>\S+)/ ) {
          my $ip       = $+{ip};
          my $wildMask = $+{wild};
          my $mask     = $self->changeWildMaskToMaskNum($wildMask);
          $self->addToRuleSrcAddressGroup( $rule, "$ip/$mask", 'ip' );
        }
        else {
          $self->addToRuleSrcAddressGroup( $rule, 'any', 'addr' );
        }

        if ( defined $dst and $dst =~ /any/ ) {
          $self->addToRuleDstAddressGroup( $rule, $dst, 'addr' );
        }
        elsif ( defined $dst and $dst =~ /object-group\s+(?<addrName>\S+)/ ) {
          $self->addToRuleDstAddressGroup( $rule, $+{addrName}, 'addr' );
        }
        elsif ( defined $dst and $dst =~ /(?<ip>\d+\.\d+\.\d+\.\d+)\s+(?<wild>\S+)/ ) {
          my $ip       = $+{ip};
          my $wildMask = $+{wild};
          my $mask     = $self->changeWildMaskToMaskNum($wildMask);
          $self->addToRuleDstAddressGroup( $rule, "$ip/$mask", 'ip' );
        }
        else {
          $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' );
        }

        if ( defined $opt ) {
          if ( $opt eq 'eq' ) {
            $port = $self->getPortName($port) if $port !~ /\d+/;
            my $name = $protocol . "/" . $port;
            my $obj  = Firewall::Config::Element::Service::H3c->new( srvName => $name, protocol => $protocol,
              dstPort => $port );
            $rule->addServiceMembers( $name, $obj );
          }
          elsif ( $opt eq 'range' ) {
            $port =~ /(?<minport>\d+)\s+(?<maxport>\d+)/;
            my $minport = $+{minport};
            my $maxport = $+{maxport};
            $minport = $self->getPortName($minport) if $minport !~ /\d+/;
            $maxport = $self->getPortName($maxport) if $maxport !~ /\d+/;
            my $dstPort = $minport . "-" . $maxport;
            my $name    = $protocol . "/" . $dstPort;
            my $obj     = Firewall::Config::Element::Service::H3c->new(
              srvName  => $name,
              protocol => $protocol,
              dstPort  => $dstPort
            );
            $rule->addServiceMembers( $name, $obj );
          }
          elsif ( $opt eq 'gt' ) {
            $port = $self->getPortName($port) if $port !~ /\d+/;
            my $dstPort = $port . "-65535";
            my $name    = $protocol . "/" . $dstPort;
            my $obj     = Firewall::Config::Element::Service::H3c->new(
              srvName  => $name,
              protocol => $protocol,
              dstPort  => $dstPort
            );
            $rule->addServiceMembers( $name, $obj );
          }
          elsif ( $opt eq 'lt' ) {
            $port = $self->getPortName($port) if $port !~ /\d+/;
            my $dstPort = "0-" . $port;
            my $name    = $protocol . "/" . $dstPort;
            my $obj     = Firewall::Config::Element::Service::H3c->new(
              srvName  => $name,
              protocol => $protocol,
              dstPort  => $dstPort
            );
            $rule->addServiceMembers( $name, $obj );
          }
          elsif ( $opt eq 'object-group' ) {
            my $portObj = $self->getPortObj($port);
            my $obj     = Firewall::Config::Element::Service::H3c->new( srvName => $port );
            for my $portrange ( @{$portObj} ) {
              if ( $portrange =~ /eq\s+(?<port>\d+)/ ) {
                my $name = $protocol . "/" . $+{port};
                $obj->addMeta( srvName => $name, protocol => $protocol, dstPort => $+{port} );

              }
              elsif ( $portrange =~ /range\s+(?<minport>\d+)\s+(?<maxport>\d+)/ ) {
                my $dstPort = $+{minport} . "-" . $+{maxport};
                my $name    = $protocol . "/" . $dstPort;
                $obj->addMeta( srvName => $name, protocol => $protocol, dstPort => $dstPort );
              }
              elsif ( $portrange =~ /gt\s+(?<port>\d+)/ ) {
                my $dstPort = $+{port} . "-65535";
                my $name    = $protocol . "/" . $dstPort;
                $obj->addMeta( srvName => $name, protocol => $protocol, dstPort => $dstPort );
              }
              elsif ( $portrange =~ /lt\s+(?<port>\d+)/ ) {
                my $dstPort = "0-" . $+{port};
                my $name    = $protocol . "/" . $dstPort;
                $obj->addMeta( srvName => $name, protocol => $protocol, dstPort => $dstPort );
              }
            } ## end for my $portrange ( @{$portObj...})
            $rule->addServiceMembers( $port, $obj );
          } ## end elsif ( $opt eq 'object-group')

        }
        else {
          my $obj = Firewall::Config::Element::Service::H3c->new( srvName => 'any', protocol => 'any' );
          $rule->addServiceMembers( 'any', $obj );
        }

        $self->addElement($rule);
      } ## end if ( $string =~ /rule\s+(?<aclRuleNum>\d+)\s+(?<action>deny|permit)\s+(?<protocol>\S+) )
    } ## end while ( defined( my $string...))

  } ## end elsif ( $string =~ /acl\s+advanced\s+((?<id>\d+)|name\s+(?<name>\S+))\s*/i)

} ## end sub parseAcl

sub changeWildMaskToMaskNum {
  my ( $self, $wildMask ) = @_;
  my $mask;
  if ( $wildMask eq '0' ) {
    $mask = 32;
  }
  else {
    my $maskForm = Firewall::Utils::Ip->new->changeWildcardToMaskForm( $+{wild} );
    $mask = Firewall::Utils::Ip->new->changeMaskToNumForm($maskForm);
  }
  return $mask;

}

sub isStaticNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /nat\s+static\s+(outbound|inbound)/i ) {
    $self->setElementType('natPool');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseStaticNat {
  my ( $self, $string ) = @_;
  my %params;
  $params{config} = $string;
  if ( $string
    =~ /nat\s+static\s+(?<fx>outbound|inbound)\s+(?<realIp>\d+\.\d+\S+)\s+(?<natIp>\S+)(.+?acl\s+(?<aclnum>(\d+)|name\s+(?<aclname>\S+)))?/i
    )
  {
    my $fx = $+{fx};
    $params{realIp}      = $+{realIp};
    $params{realIp}      = $+{natIp} if $fx eq 'inbound';
    $params{natIp}       = $+{natIp};
    $params{natIp}       = $+{realIp} if $fx eq 'inbound';
    $params{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $params{realIp}, 32 );
    $params{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $params{natIp},  32 );
    $params{aclNum}      = $+{aclnum}  if defined $+{aclnum};
    $params{aclName}     = $+{aclname} if defined $+{aclname};
  }
  elsif (
    $string =~ /nat\s+static\s+(?<fx>outbound|inbound)\s+net-to-net\s+
        (?<minIp>\S+)\s+(?<maxIp>\S+)\s+(global|local)\s+(?<natNet>\S+)\s+((?<mask>\d+)(\s+|$)|(?<maskStr>\d+\.\d+\.\d+\.\d+))
        (.+?acl\s+(?<aclnum>(\d+)|name\s+(?<aclname>\S+)))?/oxi
    )
  {
    my $fx = $+{fx};
    if ( $fx eq 'outbound' ) {
      $params{realIp} = $+{minIp} . "-" . $+{maxIp};
      my $mask;
      $mask                = $+{mask}                                                     if defined $+{mask};
      $mask                = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{maskStr} ) if defined $+{maskStr};
      $params{natIp}       = $+{natNet} . "/" . $mask;
      $params{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpRange( $+{minIp}, $+{maxIp} );
      $params{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natNet}, $mask );
    }
    else {

      #inboud nat是相反的
      $params{natIp} = $+{minIp} . "-" . $+{maxIp};
      my $mask;
      $mask                = $+{mask}                                                     if defined $+{mask};
      $mask                = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{maskStr} ) if defined $+{maskStr};
      $params{realIp}      = $+{natIp} . "/" . $mask;
      $params{natIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpRange( $+{minIp}, $+{maxIp} );
      $params{realIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natNet}, $mask );

    }
    $params{aclNum}  = $+{aclnum}  if defined $+{aclnum};
    $params{aclName} = $+{aclname} if defined $+{aclname};

  }
  elsif (
    /nat\s+static\s+(?<fx>outbound|inbound)\s+object-group\s+(?<realIp>\S+)\s+object-group\s+(?<natIp>\S+)
        (.+?acl\s+(?<aclnum>(\d+)|name\s+(?<aclname>\S+)))?/oxi
    )
  {
    my $fx = $+{fx};
    $params{realIp}      = $+{realIp};
    $params{realIp}      = $+{natIp} if $fx eq 'inbound';
    $params{natIp}       = $+{natIp};
    $params{natIp}       = $+{realIp} if $fx eq 'inbound';
    $params{realIpRange} = $self->getAddress( $+{realIp} )->range;
    $params{natIpRange}  = $self->getAddress( $+{natIp} )->range;
    $params{aclNum}      = $+{aclnum}  if defined $+{aclnum};
    $params{aclName}     = $+{aclname} if defined $+{aclname};

  }
  my $staticnat = Firewall::Config::Element::StaticNat::H3c->new(%params);
  $self->addElement($staticnat);
} ## end sub parseStaticNat

sub isNatPool {
  my ( $self, $string ) = @_;
  if ( $string =~ /nat\s+address-group\s+\d+/i ) {
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
  if ( $string =~ /nat\s+address-group\s+(?<id>\d+)(\s+name\s+(?<name>\S+))?/i ) {
    my %params;
    $params{config}   = $string;
    $params{name}     = $+{name} if defined $+{name};
    $params{poolName} = $+{id}   if defined $+{id};
    $params{poolName} = $+{name} if not defined $+{id};
    my @poolIp;
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      if ( $string =~ /address\s+(?<range>\S+\s+\S+)/ ) {
        push @poolIp, $+{range};
      }
    }
    $params{poolIp} = \@poolIp;
    my $natpool = Firewall::Config::Element::NatPool::H3c->new(%params);
    $self->addElement($natpool);
    if ( defined $params{name} ) {
      $self->elements->natPool->{$params{name}} = $natpool;
    }
  } ## end if ( $string =~ /nat\s+address-group\s+(?<id>\d+)(\s+name\s+(?<name>\S+))?/i)
} ## end sub parseNatPool

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
    my $name = $+{name};

    #my $isNat =0;
    my $interface;
    $interface = Firewall::Config::Element::Interface::H3c->new( name => $name, config => $string );
    $self->addElement($interface);
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      $interface->{config} .= "\n" . $string;
      if ( $string =~ /ip\s+address\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
        $interface->{ipAddress}     = $+{ip};
        $interface->{mask}          = $+{mask};
        $interface->{interfaceType} = 'layer3';
        my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        my $route   = Firewall::Config::Element::Route::H3c->new(
          network      => $+{ip},
          mask         => $maskNum,
          dstInterface => $name,
          nextHop      => $+{ip}
        );
        $self->addElement($route);
        $interface->addRoute($route);
      }
      elsif ( $string =~ /nat/ ) {
        chomp $string;
        $string .= " interface $name";
        $self->config->config->[ $self->lineNumber - 1 ] = $string;
        $self->ignoreLine;
      }

    } ## end while ( defined( $string ...))
  } ## end if ( $string =~ /^interface\s+(?<name>\S+)/i)
} ## end sub parseInterface

sub isZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /security-zone\s+name\s+\S+/i ) {
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
  if ( $string =~ /security-zone\s+name\s+(?<name>\S+)/i ) {
    my $name = $+{name};
    my $zone;
    $zone = Firewall::Config::Element::Zone::H3c->new( name => $name, fwId => $self->fwId, config => $string );
    $self->addElement($zone);
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      $zone->{config} .= "\n" . $string;
      if ( $string =~ /import\s+interface\s+(?<intName>\S+)/i ) {
        my $interface = $self->getInterface( $+{intName} );
        $interface->{zoneName} = $name;
        $zone->addInterface($interface);
      }

    }
  } ## end if ( $string =~ /security-zone\s+name\s+(?<name>\S+)/i)

} ## end sub parseZone

sub isPortObj {
  my ( $self, $string ) = @_;
  if ( $string =~ /object-group\s+port/i ) {
    $self->setElementType('port');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getPortObj {
  my ( $self, $name ) = @_;
  return $self->{element}{portObj}{$name};
}

sub parsePortObj {
  my ( $self, $string ) = @_;
  if ( $string =~ /object-group\s+port\s+(?<name>\S+)/i ) {
    my $name = $+{name};
    my @ports;
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      if ( $string =~ /port\s+(?<port>.+)$/i ) {
        push @ports, $+{port};
      }
    }
    $self->{element}{portObj}{$name} = \@ports;
  }
}

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /object-group\s+ip\s+address/i ) {
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
  if ( $string =~ /object-group\s+ip\s+address\s+((?<name>\S+)|"(?<name>.+?)")/i ) {
    my $name    = $+{name};
    my $address = Firewall::Config::Element::Address::H3c->new( addrName => $name, config => $string );
    $self->addElement($address);
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      $address->{config} .= "\n" . $string;
      if ( $string =~ /network\s+subnet\s+(?<ip>\S+)\s+(?<mask>\S+)/ ) {
        my $ipmask = $+{ip} . "/" . Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        $address->addMember( {'ipmask' => $ipmask} );

      }
      elsif ( $string =~ /network\s+range\s+(?<range>\S+\s+\S+)/i ) {

        $address->addMember( {'range' => $+{range}} );

      }
      elsif ( $string =~ /network\s+group-object\s+((?<addName>\S+)|"(?<addName>.+?)")/i ) {
        my $addrObj = $self->getAddress( $+{addName} );
        if ( defined $addrObj ) {
          $address->addMember( {'obj' => $addrObj} );
        }
        else {
          push @{$address->{needcomplete}}, $+{addName};
        }
      }
      elsif ( $string =~ /network\s+host\s+(address|name)\s+(?<ip>\S+)/ ) {
        my $ip = $+{ip};
        $address->addMember( {'ipmask' => $ip . "/32"} ) if $ip =~ /\d+\.\d+\.\d+\.\d+/;

      }
      elsif ( $string =~ /description\s+/ ) {
      }
      else {
        $self->warn( "can't parse address" . $string );
      }

    } ## end while ( defined( $string ...))
  } ## end if ( $string =~ /object-group\s+ip\s+address\s+((?<name>\S+)|"(?<name>.+?)")/i)
} ## end sub parseAddress

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /object-group\s+service/ox ) {
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
  if ( $string =~ /object-group\s+service\s+((?<name>\S+)|"(?<name>.+?)")/i ) {
    my %params;
    $params{srvName} = $+{name};
    my $config = $string;
    my $service;
    $service = Firewall::Config::Element::Service::H3c->new(%params);
    $self->addElement($service);
    while ( defined( $string = $self->nextUnParsedLine ) ) {
      if ( $string =~ /^\s*#/ ) {
        last;
      }
      $config .= "\n" . $string;
      if (
        $string =~ /service\s+(?<proto>\S+)
                (\s+source\s+(?<sp>eq|range|gt|lt)\s+\d+(\s+\d+)?\s*)?
                (\s+destination\s+(?<dp>eq|range|gt|lt)\s+((?<minport>\d+)(\s+(?<maxport>\d+))?))?$/oxi
        )
      {
        $params{protocol} = $+{proto};
        my $minport   = $+{minport};
        my $maxport   = $+{maxport};
        my $portrange = $+{dp};
        if ( defined $portrange ) {
          if ( $portrange eq 'eq' ) {
            $params{dstPort} = $minport;
          }
          elsif ( $portrange eq 'range' ) {
            $params{dstPort} = $minport . "-" . $maxport;
          }
          elsif ( $portrange eq 'gt' ) {
            $params{dstPort} = $minport . "-65535";
          }
          elsif ( $portrange eq 'lt' ) {
            $params{dstPort} = "1-" . $minport;
          }
        }
        else {
          if ( $params{protocol} =~ /tcp|udp|icmp/i ) {
            $params{dstPort} = '1-65535';
          }
        }
        if ( defined $service ) {
          $service->addMeta(%params);
        }
        else {
          $service = Firewall::Config::Element::Service::H3c->new(%params);
          $self->addElement($service);
        }

      }
      elsif ( $string =~ /service\s+group-object\s+((?<obj>\S+)|"(?<obj>.+?)")/i ) {
        my $serObj = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{obj} );
        if ( defined $serObj ) {
          $service->addMeta($serObj);
        }
        else {
          push @{$service->{needcomplete}}, $+{obj};
        }
      }
      elsif ( $string =~ /description\s+/ ) {
      }
      else {
        $self->warn( "can't parse service" . $string );
      }

    } ## end while ( defined( $string ...))
    $service->{config} = $config;
  } ## end if ( $string =~ /object-group\s+service\s+((?<name>\S+)|"(?<name>.+?)")/i)

} ## end sub parseService

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::H3c->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub getServiceOrServiceGroupFromSrvGroupMemberName {
  my ( $self, $srvGroupMemberName ) = @_;
  my $obj = $self->getPreDefinedService($srvGroupMemberName) // $self->getService($srvGroupMemberName);
  return $obj;
}

sub isSchedule {
  my ( $self, $string ) = @_;
  if ( $string =~ /time-range\s+\S+/i ) {
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
  if ( $string =~ /time-range\s+(?<name>\S+)\s+from\s+(?<startdate>\S+\s+\S+)\s+to\s+(?<enddate>\S+\s+\S+)/i ) {
    my %params;
    $params{schName} = $+{name};
    $params{config}  = $string;
    my $schedule;
    $params{schType}   = 'onetime';
    $params{startDate} = $+{startdate} if defined $+{startdate};
    $params{endDate}   = $+{enddate};
    $schedule          = Firewall::Config::Element::Schedule::H3c->new(%params);
    $self->addElement($schedule);
  }
  elsif ( $string =~ /time-range\s+(?<name>\S+)\s+(?<starttime>\S+)\s+to\s+(?<endtime>\S+)\s+(?<weekday>.+)/ ) {
    my %params;
    $params{schName}   = $+{name};
    $params{config}    = $string;
    $params{schType}   = 'recurring';
    $params{startTime} = $+{starttime} if defined $+{starttime};
    $params{endTime}   = $+{endtime};
    $params{day}       = $+{weekday};
    my $schedule = Firewall::Config::Element::Schedule::H3c->new(%params);
    $self->addElement($schedule);
  }
  else {
    $self->warn( "can't parse schedule " . $string );
  }

} ## end sub parseSchedule

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /ip\s+route-static\s+\d+\.\d+\.\d+\.\d+/i ) {
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
    $string =~ /ip\s+route-static\s+(vpn-instance\s+(?<vpn>\S+)\s+)?(?<net>\S+)\s+(?<mask>\d+|\d+\.\d+\.\d+\.\d+)\s+
        ((?<dstint>[a-zA-Z]+\S+)\s+)?(?<nexthop>\d+\.\d+\.\d+\.\d+)
    /ox
    )
  {
    my %params;
    $params{config}       = $string;
    $params{network}      = $+{net};
    $params{vpn}          = $+{vpn}    if defined $+{vpn};
    $params{dstInterface} = $+{dstint} if defined $+{dstint};
    $params{nextHop}      = $+{nexthop};
    my $mask = $+{mask};

    if ( $mask =~ /\d+\.\d+\.\d+\.\d+/ ) {
      $params{mask} = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
    }
    else {
      $params{mask} = $mask;
    }
    my $route = Firewall::Config::Element::Route::H3c->new(%params);
    $self->addElement($route);
  }
  else {

    $self->warn( "can't parse route " . $string );
  }

} ## end sub parseRoute

sub isDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /nat\s+outbound\s+|nat\s+server/i ) {
    $self->setElementType('router');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub parseDynamicNat {
  my ( $self, $string ) = @_;
  if ( not defined $self->{"natLine"} ) {
    $self->{"natLine"} = 0;
  }
  else {
    $self->{"natLine"}++;
  }
  if ( $string
    =~ /nat\s+outbound\s+((name\s+(?<aclName>\S+))|(?<aclNum>\d+))?(\s+address-group\s+(?<poolName>\d+))?\s+interface\s+(?<name>\S+)/
    )
  {
    my $aclNum = $+{aclName};
    $aclNum = $+{aclNum} if defined $+{aclNum};
    my $interfaceName = $+{name};
    my $poolName      = $+{poolName};
    my $interface     = $self->getInterface($interfaceName);
    my %param;

    $param{toZone}       = $interface->{zoneName};
    $param{natDirection} = 'source';
    $param{id}           = $self->{"natLine"};
    $param{natInterface} = $interfaceName;
    my $config = "interface $interfaceName";
    my $temp   = $string;
    $temp =~ s/\s+interface\s+(?<name>\S+)//;
    $config .= "\n" . $temp;
    $param{config} = $config;

    if ( defined $aclNum ) {
      my $acl = $self->getAcl($aclNum);
      if ( defined $acl ) {
        my $srcSet = Firewall::Utils::Set->new;
        my $dstSet = Firewall::Utils::Set->new;
        my $srvSet = Firewall::Utils::Set->new;
        for my $rule ( @{$acl} ) {
          $srcSet->mergeToSet( $rule->srcAddressGroup->range );
          $dstSet->mergeToSet( $rule->dstAddressGroup->range );
          $srvSet->mergeToSet( $rule->serviceGroup->range );
        }
        $param{srcIpRange} = $srcSet;
        $param{dstIpRange} = $dstSet;
        $param{srvRange}   = $srvSet;
      }

    }
    else {
      $param{srcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', '0' );
      $param{dstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', '0' );
      $param{srvRange}   = Firewall::Utils::Ip->new->getRangeFromService('any');
    }
    if ( defined $poolName ) {
      my $pool = $self->getNatPool($poolName);
      $param{natSrcIpRange} = $pool->poolRange;
    }
    else {
      my $natIp = $interface->{ipAddress};
      $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $natIp, '32' );
    }
    my $dyNat = Firewall::Config::Element::DynamicNat::H3c->new(%param);
    $self->addElement($dyNat);

  }
  elsif (
    $string =~ /nat\s+server\s+(protocol\s+(?<proto>\S+)\s+)?global\s+
        (?<natIp1>\d+\.\d+\.\d+\.\d+)(\s+(?<natIp2>\d+\.\d+\.\d+\.\d+))?\s+((?<natPort>\d+)\s*)?
        inside\s+
        (?<realIp1>\d+\.\d+\.\d+\.\d+)(\s+(?<realIp2>\d+\.\d+\.\d+\.\d+))?(\s+(?<port>\d+))?
        (\s*(name\s+(?<aclName>\S+))|(?<aclNum>\d+))?
        \s+interface\s+(?<name>\S+)/ox
    )
  {
    my $proto  = $+{proto};
    my $natIp1 = $+{natIp1};
    my $natIp2 = $+{natIp2};
    $natIp2 = $natIp1 if not defined $natIp2;
    my $natPort = $+{natPort};
    my $realIp1 = $+{realIp1};
    my $realIp2 = $+{realIp2};
    $realIp2 = $realIp1 if not defined $realIp2;
    my $port          = $+{port};
    my $interfaceName = $+{name};
    my $interface     = $self->getInterface($interfaceName);
    my $aclNum        = $+{aclName};
    $aclNum = $+{aclNum} if defined $+{aclNum};
    my %param;
    $param{fromZone}     = $interface->{zoneName};
    $param{natDirection} = 'destination';
    $param{id}           = $self->{"natLine"};
    $param{config}       = "interface $interfaceName";
    $string =~ s/\s+interface\s+(?<name>\S+)//;
    $param{config} .= "\n" . $string;

    if ( defined $aclNum ) {
      my $acl = $self->getAcl($aclNum);
      if ( defined $acl ) {
        my $srcSet = Firewall::Utils::Set->new;
        my $srvSet = Firewall::Utils::Set->new;
        for my $rule ( @{$acl} ) {
          $srcSet->mergeToSet( $rule->srcAddressGroup->range );
          $srvSet->mergeToSet( $rule->serviceGroup->range );
        }
        $param{srcIpRange} = $srcSet;
        $param{srvRange}   = $srvSet;
      }

    }
    else {
      $param{srcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0', '0' );
      $param{srvRange}   = Firewall::Utils::Ip->new->getRangeFromService('any');
    }

    $param{dstIpRange}    = Firewall::Utils::Ip->new->getRangeFromIpRange( $realIp1, $realIp2 );
    $param{natDstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpRange( $natIp1,  $natIp2 );
    if ( defined $proto ) {
      $param{srvRange}    = Firewall::Utils::Ip->new->getRangeFromService("$proto/$port");
      $param{natSrvRange} = Firewall::Utils::Ip->new->getRangeFromService("$proto/$natPort");
    }
    my $dyNat = Firewall::Config::Element::DynamicNat::H3c->new(%param);
    $self->addElement($dyNat);

  } ## end elsif ( $string =~ /nat\s+server\s+(protocol\s+(?<proto>\S+)\s+)?global\s+ )
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
  if ( $string =~ /object-policy\s+ip\s+/i ) {
    $self->setElementType('rule');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRule {
  my ( $self, $objName, $policyId ) = @_;
  my $rule = $self->getElement( 'rule', $objName, $policyId );
  return $rule;
}

sub parseRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /object-policy\s+ip\s+(?<name>\S+)/ ) {
    my $obj_name = $+{name};
    my $zonePair = $self->getZonePair();
    my %param;
    my $objdef = $string;
    my $fromZone;
    my $toZone;
    if ( defined $zonePair->{obj}{$obj_name} ) {
      $fromZone = $zonePair->{obj}{$obj_name}{fromZone};
      $toZone   = $zonePair->{obj}{$obj_name}{toZone};
    }
    else {
      return;
    }

    while ( defined( my $string = $self->nextUnParsedLine ) ) {
      last if $string =~ /^\s*#/;
      if (
        $string =~ /rule\s+(?<id>\d+)\s+(?<action>\S+)
                (\s+source-ip\s+((?<src>\S+)|"(?<src>.+?)"))?
                (\s+destination-ip\s+((?<dst>\S+)|"(?<dst>.+?)"))?
                (\s+service\s+((?<srv>\S+)|"(?<srv>.+?)"))?
                (.+?)?
                (\s+time-range\s+(?<time>\S+))?/ox
        )
      {
        my %param;
        $param{policyId} = $+{id};
        $param{fromZone} = $fromZone;
        $param{toZone}   = $toZone;
        $param{schName}  = $+{'time'} if defined $+{'time'};
        $param{content}  = $objdef;
        $param{ruleType} = 'obj';
        $param{objName}  = $obj_name;
        $param{content} .= "\n" . $string;
        my $src = $+{src};
        my $dst = $+{dst};
        my $ser = $+{srv};
        my $rule;
        my $isNew = 1;

        if ( $+{action} eq 'pass' ) {
          $param{action} = 'permit';
          $rule = Firewall::Config::Element::Rule::H3c->new(%param);
          $self->addElement($rule);
        }
        elsif ( $+{action} eq 'drop' ) {
          $param{action} = 'deny';
          $rule = Firewall::Config::Element::Rule::H3c->new(%param);
          $self->addElement($rule);
        }
        elsif ( $+{action} eq 'append' ) {
          $rule = $self->getRule( $obj_name, $param{policyId} );
          $rule->{content} .= $string;
          $isNew = 0;
        }
        else {
          $rule = $self->getRule( $obj_name, $param{policyId} );
          $rule->{content} .= $string;
          next;
        }

        if ( defined $src ) {
          $self->addToRuleSrcAddressGroup( $rule, $src, 'addr' );
        }
        else {
          $self->addToRuleSrcAddressGroup( $rule, 'any', 'addr' ) if $isNew;
        }

        if ( defined $dst ) {
          $self->addToRuleDstAddressGroup( $rule, $dst, 'addr' );
        }
        else {
          $self->addToRuleDstAddressGroup( $rule, 'any', 'addr' ) if $isNew;
        }

        if ( defined $ser ) {
          $self->addToRuleServiceGroup( $rule, $ser );
        }
        else {
          $self->addToRuleServiceGroup( $rule, 'any' ) if $isNew;
        }

      } ## end if ( $string =~ /rule\s+(?<id>\d+)\s+(?<action>\S+) )

    } ## end while ( defined( my $string...))

  } ## end if ( $string =~ /object-policy\s+ip\s+(?<name>\S+)/)
} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName, $type ) = @_;
  my $name = $srcAddrName;
  my $obj;
  if ( $type eq 'addr' ) {
    if ( $srcAddrName =~ /any|any-ip/io ) {
      unless ( $obj = $self->getAddress($srcAddrName) ) {
        $obj = Firewall::Config::Element::Address::H3c->new( addrName => $srcAddrName );
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
    $obj = Firewall::Config::Element::Address::H3c->new( addrName => $srcAddrName );
    $obj->addMember( {ipmask => "$srcAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $srcAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::H3c->new( addrName => $ipmin . '-' . $ipmax );
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
        $obj = Firewall::Config::Element::Address::H3c->new( addrName => $dstAddrName );
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
    $obj = Firewall::Config::Element::Address::H3c->new( addrName => $dstAddrName );
    $obj->addMember( {ipmask => "$dstAddrName"} );
  }
  elsif ( $type eq 'range' ) {
    my ( $ipmin, $ipmax ) = split( '\s+', $dstAddrName );
    $name = $ipmin . '-' . $ipmax;
    $obj  = Firewall::Config::Element::Address::H3c->new( addrName => $ipmin . '-' . $ipmax );
    $obj->addMember( {range => "$dstAddrName"} );
  }
  $rule->addDstAddressMembers( $name, $obj );
} ## end sub addToRuleDstAddressGroup

sub addToRuleServiceGroup {
  my ( $self, $rule, $srvName ) = @_;
  my $obj;
  if ( $srvName =~ /^\s*any\s*$/i ) {
    $obj = Firewall::Config::Element::Service::H3c->new( srvName => 'any', protocol => 'any' );
    $rule->addServiceMembers( $srvName, $obj );
  }
  else {
    if ( $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($srvName) ) {
      $obj->{refnum} += 1;
      $rule->addServiceMembers( $srvName, $obj );
    }
    else {
      $self->warn("的 srvName $srvName 不是 service 不是 preDefinedService 也不是 serviceGroup\n");
    }
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

sub getPortName {
  my ( $self, $portName ) = @_;
  my %portHash;
  $portHash{'bgp'}      = 179;
  $portHash{'chargen'}  = 19;
  $portHash{cmd}        = 514;
  $portHash{daytime}    = 13;
  $portHash{discard}    = 9;
  $portHash{dns}        = 53;
  $portHash{domain}     = 53;
  $portHash{echo}       = 7;
  $portHash{'exec'}     = 512;
  $portHash{finger}     = 79;
  $portHash{'ftp'}      = 21;
  $portHash{'ftp-data'} = 20;
  $portHash{gopher}     = 70;
  $portHash{hostname}   = 101;
  $portHash{irc}        = 194;
  $portHash{klogin}     = 543;
  $portHash{kshell}     = 544;
  $portHash{login}      = 513;
  $portHash{lpd}        = 515;
  $portHash{nntp}       = 119;
  $portHash{pop2}       = 109;
  $portHash{pop3}       = 110;
  $portHash{smtp}       = 25;
  $portHash{sunrpc}     = 111;
  $portHash{tacacs}     = 49;
  $portHash{talk}       = 517;
  $portHash{telnet}     = 23;
  $portHash{'time'}     = 37;
  $portHash{uucp}       = 540;
  $portHash{whois}      = 43;
  $portHash{www}        = 80;
  return $portHash{$portName};
} ## end sub getPortName

__PACKAGE__->meta->make_immutable;
1;
