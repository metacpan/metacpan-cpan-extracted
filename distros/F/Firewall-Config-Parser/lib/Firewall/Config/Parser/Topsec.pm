package Firewall::Config::Parser::Topsec;

use Carp;
use Encode;
use Moose;
use namespace::autoclean;

use Firewall::Utils::Ip;
use Firewall::Config::Element::Address::Topsec;
use Firewall::Config::Element::AddressGroup::Topsec;
use Firewall::Config::Element::Service::Topsec;
use Firewall::Config::Element::ServiceGroup::Topsec;
use Firewall::Config::Element::Schedule::Topsec;
use Firewall::Config::Element::Rule::Topsec;
use Firewall::Config::Element::StaticNat::Topsec;
use Firewall::Config::Element::Route::Topsec;
use Firewall::Config::Element::Interface::Topsec;
use Firewall::Config::Element::Zone::Topsec;
use Firewall::Config::Element::DynamicNat::Topsec;
use experimental 'smartmatch';
use Mojo::Util qw(dumper);

with 'Firewall::Config::Parser::Role';

sub parse {
  my $self = shift;
  while ( my $string = $self->nextUnParsedLine ) {
    if   ( $self->isInterface($string) ) { $self->parseInterface($string) }
    else                                 { $self->ignoreLine }
  }
  $self->addInterfaceVlan;

  # 配置解析路由、网络安全区
  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isRoute($string) )   { $self->parseRoute($string) }
    elsif ( $self->isZone($string) )    { $self->parseZone($string) }
    elsif ( $self->isAddress($string) ) { $self->parseAddress($string) }
    elsif ( $self->isAddressGroup($string) ) {
      $self->parseAddressGroup($string);
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

    #elsif ( $self->isActive($string)       ) { $self->setActive($string)         }
    else { $self->ignoreLine }
  }
  $self->addZoneNameToVlanInt;
  $self->addRouteToInterface;
  $self->addZoneRange;

  # 解析NAT
  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isNat($string) )  { $self->parseNat($string) }
    elsif ( $self->isRule($string) ) { $self->parseRule($string) }
    else                             { $self->ignoreLine }
  }
} ## end sub parse

sub isInterface {
  my ( $self, $string ) = @_;
  if ( $string =~ /^network\s+interface\s+(\S+)/i ) {
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
  $self->backtrackLine;
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string !~ /^network\s+interface\s+(\S+)/i ) {
      $self->backtrackLine;
      last;
    }
    elsif ( $string =~ /^network\s+interface\s+(?<name>\S+)\s+(?<other>.+)/i ) {
      my $name  = $+{name};
      my $other = $+{other};
      my $interface;
      unless ( $interface = $self->getInterface($name) ) {
        $interface = Firewall::Config::Element::Interface::Topsec->new(
          name   => $name,
          config => $string
        );
        $self->addElement($interface);
      }
      else {
        $interface->{config} .= "\n" . $string;
      }
      if ( $other =~ /ip\s+add\s+(?<ip>\S+)\s+mask\s+(?<mask>\S+)/i ) {
        $interface->{ipAddress} = $+{ip};
        my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
        $interface->{mask}          = $maskNum;
        $interface->{interfaceType} = 'layer3';
        my $route = Firewall::Config::Element::Route::Topsec->new(
          type    => 'connected',
          network => $+{ip},
          mask    => $maskNum,
          nextHop => $+{ip},
          routeId => 9999
        );
        $self->addElement($route);
        $interface->addRoute($route);
      }
      if ( $other =~ /switchport\s+mode\s+(?<accessMode>\S+)/i ) {
        if ( $interface->{interfaceType} ne 'layer3' ) {
          $interface->{accessMode} = $+{accessMode};
        }
      }
      if ( $other =~ /switchport\s+access-vlan\s+(?<vlan>\d+)/i ) {
        if ( $interface->{accessMode} eq 'access' and $interface->{interfaceType} ne 'layer3' ) {
          push @{$interface->accessVlan}, $+{vlan};
        }
      }
      if ( $other =~ /switchport\s+trunk\s+allowed-vlan\s+(?<vlans>\S+)/i ) {
        if ( $interface->{accessMode} eq 'trunk' and $interface->{interfaceType} ne 'layer3' ) {
          my @vlans = split( ',', $+{vlans} );
          @{$interface->accessVlan} = @vlans;
        }
      }
    }
    else {
      $self->warn("interface $string 分析不出来\n");
    }
  } ## end while ( $string = $self->...)
} ## end sub parseInterface

sub addInterfaceVlan {
  my $self       = shift;
  my $interfaces = $self->{elements}{interface};
  for my $intName ( keys %{$interfaces} ) {
    if ( $intName !~ /vlan/i ) {
      if ( $interfaces->{$intName}{interfaceType} ne 'layer3' ) {
        my @vlans = $interfaces->{$intName}{accessVlan};
        for my $vlan (@vlans) {
          my $intVlanName = 'vlan.' . '0' x ( 4 - ( length $vlan ) ) . $vlan;
          my $intvlan     = $self->getInterface($intVlanName);
          if ( defined $intvlan ) {
            $interfaces->{$intName}{range}->mergeToSet( $intvlan->{range} );
            $intvlan->{interface}{$intName} = undef;                                 #add interface to vlan too;
            $intvlan->{zoneName} = $interfaces->{$intName}->{zoneName};
          }
        }
      }
    }
  }
} ## end sub addInterfaceVlan

sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /^network\s+route\s+add\s+/i ) {
    $self->setElementType('route');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getRoute {
  my ( $self, $name ) = @_;
  return $self->getElement( 'route', $name );
}

sub parseRoute {
  my ( $self, $string ) = @_;
  $self->backtrackLine;
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string !~ /^network\s+route\s+add\s+/i ) {
      $self->backtrackLine;
      last;
    }
    if ( $string
      =~ /^network\s+route\s+add\s+dst\s+(?<netmask>\S+)\s+(gw\s+(?<gw>\S+)\s*)?(metric\s+(?<metric>\d+)\s*)?(dev\s+(?<dev>\S+)\s*)?id\s+(?<id>\d+)/i
      )
    {
      my %param;
      $param{config} = $string;
      my ( $network, $mask ) = split( '/', $+{netmask} );
      $param{network}      = $network;
      $param{mask}         = $mask;
      $param{nextHop}      = $+{gw} if defined $+{gw};
      $param{type}         = 'static';
      $param{dstInterface} = $+{dev}    if defined $+{dev};
      $param{distance}     = $+{metric} if defined $+{metric};
      $param{routeId}      = $+{id};
      my $route = Firewall::Config::Element::Route::Topsec->new(%param);
      $self->addElement($route);
    }
    else {
      $self->warn("route $string 分析不出来\n");
    }
  } ## end while ( $string = $self->...)
} ## end sub parseRoute

sub isZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ID\s+(\d+)\s+define\s+area\s+add\s+name/i ) {
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
  $self->backtrackLine;
  while ( $string = $self->nextUnParsedLine ) {
    if ( $string !~ /^ID\s+(\d+)\s+define\s+area\s+add\s+name/i ) {
      $self->backtrackLine;
      last;
    }
    elsif ( $string =~ /^ID\s+(\d+)\s+define\s+area\s+add\s+name\s+(?<name>\S+)\s+attribute\s+'(?<ints>.+)'\s+/i ) {
      my @ints = split( '\s+', $+{ints} );
      my $zone = Firewall::Config::Element::Zone::Topsec->new(
        fwId   => $self->fwId,
        name   => $+{name},
        config => $string
      );
      $self->addElement($zone);
      for my $intName (@ints) {
        my $interface = $self->getInterface($intName);
        $zone->addInterface($interface) unless defined $zone->interfaces->{$interface->sign};
        $interface->{zoneName} = $zone->name;
      }
    }
    else {
      $self->warn("zone $string 分析不出来\n");
    }
  } ## end while ( $string = $self->...)
} ## end sub parseZone

sub addZoneNameToVlanInt {
  my $self       = shift;
  my $interfaces = $self->{elements}{interface};
  for my $intName ( keys %{$interfaces} ) {
    if ( $intName =~ /vlan/i ) {
      if ( defined( my $ints = $interfaces->{$intName}{interface} ) ) {
        my $phyIntName = ( keys %{$ints} )[0];
        my $phyInt     = $self->getInterface($phyIntName);
        $interfaces->{$intName}{zoneName} = $phyInt->{zoneName};
      }
    }
  }
}

sub addRouteToInterface {
  my $self           = shift;
  my $routeIndex     = $self->elements->{route};
  my $interfaceIndex = $self->elements->{interface};
  for my $route ( values %{$routeIndex} ) {
    if ( defined $route->{dstInterface} ) {
      my $interface = $self->getInterface( $route->{dstInterface} );
      $interface->addRoute($route);
    }
    else {
      for my $interface ( values %{$interfaceIndex} ) {
        next if $interface->{interfaceType} ne 'layer3';
        my $intSet  = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{ipAddress}, $interface->{mask} );
        my $routset = Firewall::Utils::Ip->new->getRangeFromIpMask( $route->{nextHop},       32 );
        if ( $intSet->isContain($routset) ) {
          $interface->addRoute($route);
          $route->{zoneName} = $interface->{zoneName};
        }
      }
    }
  }
} ## end sub addRouteToInterface

sub addZoneRange {
  my $self = shift;
  for my $zone ( values %{$self->elements->{zone}} ) {
    for my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
  }
}

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ID\s+(\d+)\s+define\s+(host|subnet|range)\s+add\s+name/i ) {
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
  my $address;
  if ( $string =~ /ID\s+(\d+)\s+define\s+(?<type>host|subnet|range)\s+add\s+name\s+(?<name>\S+)\s+(?<other>.+)/i ) {
    my $name = $+{name};
    $address = $self->getAddress($name);
    unless ( defined $address ) {
      $address = Firewall::Config::Element::Address::Topsec->new(
        addrName => $name,
        config   => $string
      );
      $self->addElement($address);
    }
    else {
      $address->{config} .= "\n" . $string;
    }
    my $other = $+{other};
    if ( $+{type} eq 'host' ) {
      $other =~ /ipaddr\s+'(?<hosts>.+)'/i;
      my @hosts = split( '\s+', $+{hosts} );
      for my $host (@hosts) {
        $address->addMember( {'ipmask' => $host . '/32'} );
      }
    }
    elsif ( $+{type} eq 'subnet' ) {
      $other =~ /ipaddr\s+(?<network>\S+)\s+mask\s+(?<mask>\S+)/i;
      my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
      $address->addMember( {'ipmask' => $+{network} . "/$maskNum"} );
    }
    elsif ( $+{type} eq 'range' ) {
      $other =~ /ip1\s+(?<ip1>\S+)\s+ip2\s+(?<ip2>\S+)/i;
      $address->addMember( {'range' => "$+{ip1} $+{ip2}"} );
    }
    else {
      $self->warn(" address $string 分析不出来\n");
    }
  }
  else {
    $self->warn("address $string 分析不出来\n");
  }
} ## end sub parseAddress

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ID\s+(\d+)\s+define\s+group_address\s+add\s+name/i ) {
    $self->setElementType('addressGroup');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getAddressGroup {
  my ( $self, $name ) = @_;
  return $self->getElement( 'addressGroup', $name );
}

sub parseAddressGroup {
  my ( $self, $string ) = @_;
  my $addGroup;
  if ( $string =~ /ID\s+(\d+)\s+define\s+group_address\s+add\s+name\s+(?<name>\S+)\s+member\s+'(?<ips>.+)'/i ) {
    my $name = $+{name};
    $addGroup = $self->getAddressGroup($name);
    unless ( defined $addGroup ) {
      $addGroup = Firewall::Config::Element::AddressGroup::Topsec->new(
        addrGroupName => $name,
        config        => $string
      );
      $self->addElement($addGroup);
    }
    else {
      $addGroup->{config} .= "\n" . $string;
    }
    my @ips = split( '\s+', $+{ips} );
    for my $address (@ips) {
      my $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName($address);
      if ( not defined $obj ) {
        $self->warn("addrGroup $name 的 addrGroupMember $address 既不是 address 也不是 addressGroup\n");
      }
      $addGroup->addAddrGroupMember( $address, $obj );
    }
  }
  else {
    $self->warn("addressGroup $string 分析不出来\n");
  }
} ## end sub parseAddressGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $addName ) = @_;
  my $obj = $self->getAddress($addName) // $self->getAddressGroup($addName);
  return $obj;
}

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ID\s+(\d+)\s+define\s+service\s+add\s+name/ox ) {
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
  if ( $string
    =~ /^ID\s+(\d+)\s+define\s+service\s+add\s+name\s+(?<name>\S+)\s+protocol\s+(?<proto>\S+)\s+port\s+(?<port1>\d+)(\s+port2\s+(?<port2>\d+))?/i
    )
  {
    my %params;
    $params{srvName} = $+{name};
    if ( $+{proto} eq '6' ) {
      $params{protocol} = 'tcp';
    }
    elsif ( $+{proto} eq '17' ) {
      $params{protocol} = 'udp';
    }
    else {
      $params{protocol} = $+{proto};
    }
    $params{dstPort} = defined $+{port2} ? $+{port1} . '-' . $+{port2} : $+{port1};
    my $service = Firewall::Config::Element::Service::Topsec->new(%params);
    $self->addElement($service);
    $service->{config} = $string;
  }
  else {
    $self->warn("service $string 分析不出来\n");
  }
} ## end sub parseService

sub getPreDefinedService {
  my ( $self, $srvName ) = @_;
  my $sign = Firewall::Config::Element::Service::Topsec->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^ID\s+(\d+)\s+define\s+group_service\s+add\s+name/ox ) {
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
  if ( $string =~ /^ID\s+(\d+)\s+define\s+group_service\s+add\s+name\s+(?<name>\S+)\s+member\s+'(?<sers>.+)'/ox ) {
    my $name     = $+{name};
    my @sers     = split( '\s+', $+{sers} );
    my $serGroup = $self->getServiceGroup($name);
    unless ( defined $serGroup ) {
      $serGroup = Firewall::Config::Element::ServiceGroup::Topsec->new(
        srvGroupName => $name,
        config       => $string
      );
      $self->addElement($serGroup);
    }
    for my $service (@sers) {
      my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName($service);
      if ( not defined $obj ) {
        $self->warn("srvGroup $name Member $+{serName} 既不是 service 不是 pre-defined service 也不是 service Group\n");
      }
      $serGroup->addSrvGroupMember( $service, $obj );
    }
  }
  else {
    $self->warn("serviceGroup $string can't parser");
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
  if ( $string =~ /^ID\s+(\d+)\s+define\s+schedule\s+add\s+name/i ) {
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
  if ( $string
    =~ /ID\s+(\d+)\s+define\s+schedule\s+add\s+name\s+(?<name>\S+)\s+(cyctype\s+weekcyc)\s+week\s+(?<day>\d+)\s+start\s+(?<startTime>\S+)\s+end\s+(?<endTime>\S+)/i
    )
  {
    my %params;
    $params{config}  = $string;
    $params{schName} = $+{name};
    $params{schType} = 'recurring';
    my @wd  = split( '', $+{day} );
    my @day = (qw/ undef monday tuesday wednesday thursday friday saturday sunday /);
    my $day = "";
    map { $day .= $day[$_] . " " } @wd;
    $params{day}       = $day;
    $params{startTime} = $+{startTime};
    $params{endTime}   = $+{endTime};
    my $schedule = Firewall::Config::Element::Schedule::Topsec->new(%params);
    $self->addElement($schedule);
  }
  elsif ( $string
    =~ /ID\s+(\d+)\s+define\s+schedule\s+add\s+name\s+(?<name>\S+)\s+(cyctype\s+yearcyc\s+)?sdate\s+(?<sd>\S+)\s+stime\s+(?<st>\S+)\s+edate\s+(?<ed>\S+)\s+etime\s+(?<et>\S+)/i
    )
  {
    my %params;
    $params{config}    = $string;
    $params{schName}   = $+{name};
    $params{schType}   = 'onetime';
    $params{startDate} = $+{sd} . " " . $+{st};
    $params{endDate}   = $+{ed} . " " . $+{et};
    my $schedule = Firewall::Config::Element::Schedule::Topsec->new(%params);
    $self->addElement($schedule);
  }
  else {
    $self->warn("Schedule $string 分析不出来\n");
  }
} ## end sub parseSchedule

sub isNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /^\s*ID\s*(\d+)\s+nat\s+policy\s+add/i ) {
    $self->setElementType('dynamicNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub getNat {
  my ( $self, $name ) = @_;
  $self->getElement( 'dynamicNat', $name );
}

sub parseNat {
  my ( $self, $string ) = @_;
  say dumper $string;
  say dumper getInterface("eth14");
  if (
    $string =~ /ID\s+(?<id>\d+)\s+nat\s+policy\s+add\s+((?<srca>srcarea|srcvlan)\s+'(?<srcareas>.+?)'\s*)?
        ((?<dsta>dstarea|dstvlan)\s+'(?<dstareas>.+?)'\s*)?(orig-src\s+'(?<src>.+?)'\s*)?(orig-dst\s+'(?<dst>.+?)'\s*)?
        (orig-service\s+'(?<srv>.+?)'\s*)?(orig-sport\s+'(?<sport>.+?)'\s*)?(trans-src\s+(?<natsrc>\S+)\s)?
        (trans-dst\s+(?<natdst>\S+)\s)?(trans-service\s+(?<natsrv>\S+)\s*)?/ox
    )
  {
    my %param;
    $param{config} = $string;
    my ( %srcareas, %dstareas );
    my ( @srcs, @dsts, @srvs );
    $param{id} = $+{id};
    if ( defined $+{srca} and $+{srca} eq 'srcarea' ) {
      map { $srcareas{$_} = undef } split( '\s+', $+{srcareas} );
    }
    elsif ( defined $+{srca} and $+{srca} eq 'srcvlan' ) {
      my @srcvlans = split( '\s+', $+{srcareas} );
      for my $vlan (@srcvlans) {
        my $area = $self->getvlanarea($vlan);
        $srcareas{$area} = undef if defined $area;
      }
    }
    if ( defined $+{dsta} and $+{dsta} eq 'dstarea' ) {
      map { $dstareas{$_} = undef } split( '\s+', $+{dstareas} );
    }
    elsif ( defined $+{dsta} and $+{dsta} eq 'dstvlan' ) {
      my @dstvlans = split( '\s+', $+{dstareas} );
      for my $vlan (@dstvlans) {
        my $area = $self->getvlanarea($vlan);
        $dstareas{$area} = undef if defined $area;
      }
    }
    if ( defined $+{src} ) {
      $param{srcIpRange} = Firewall::Utils::Set->new;
      @srcs = split( '\s+', $+{src} );
      for my $src (@srcs) {
        my $address = $self->getAddress($src);
        my $srcZone = $self->getZoneFromRange( $address->range );
        $srcareas{$srcZone} = undef if defined $srcZone;
        $param{srcIpRange}->mergeToSet( $address->range ) if defined $address;
      }

    }
    if ( defined $+{dst} ) {
      $param{dstIpRange} = Firewall::Utils::Set->new;
      @dsts = split( '\s+', $+{dst} );
      for my $dst (@dsts) {
        my $address = $self->getAddress($dst);
        my $dstZone = $self->getZoneFromRange( $address->range );
        $dstareas{$dstZone} = undef if defined $dstZone;
        $param{dstIpRange}->mergeToSet( $address->range ) if defined $address;
      }
    }
    if ( defined $+{srv} ) {
      $param{srvRange} = Firewall::Utils::Set->new;
      @srvs = split( '\s+', $+{srv} );
      for my $srv (@srvs) {
        my $service = $self->getService($srv);
        $param{srvRange}->mergeToSet( $service->range ) if defined $service;
      }
    }
    if ( defined $+{natsrc} ) {
      say dumper $+{natsrc};
      if ( $+{natsrc} =~ /eth/ ) {
        my $interface = $self->getInterface( $+{natsrc} );
        my $addr      = $interface->{ipAddress};
        $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $addr, 32 );
      }
      $param{natDirection}  = 'source';
      $param{natSrcIpRange} = Firewall::Utils::Set->new;
      my @natsrcs = split( '\s+', $+{natsrc} );
      for my $natsrc (@natsrcs) {
        my $address = $self->getAddress($natsrc);
        if ( not defined $address ) {
          my $interface = $self->getInterface( $+{$address} );
          my $addr      = $interface->{ipAddress} if defined $interface->{ipAddress};
          $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $addr, 32 );
        }
        else {
          $param{natSrcIpRange}->mergeToSet( $address->range ) if defined $address;
        }
      }
    } ## end if ( defined $+{natsrc...})
    if ( defined $+{natdst} ) {
      $param{natDirection}  = 'destination';
      $param{natDstIpRange} = Firewall::Utils::Set->new;

      if ( $+{natdst} =~ /eth/ ) {
        my $interface = $self->getInterface( $+{natdst} );
        my $addr      = $interface->{ipAddress};
        $param{natSrcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $addr, 32 );
      }

      my @natdsts = split( '\s+', $+{natdst} );
      for my $natdst (@natdsts) {
        my $address = $self->getAddress($natdst);
        if ( not defined $address ) {
          my $interface = $self->getInterface( $+{$address} );
          my $addr      = $interface->{ipAddress} if defined $interface->{ipAddress};
          $param{natDstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $addr, 32 );
        }
        else {
          $param{natDstIpRange}->mergeToSet( $address->range ) if defined $address;
        }
      }
    } ## end if ( defined $+{natdst...})
    if ( defined $+{natsrv} ) {
      my $service = $self->getService( $+{natsrv} );
      $param{natSrvRange} = $service->range;
    }
    for my $srcarea ( keys %srcareas ) {
      for my $dstarea ( keys %dstareas ) {
        $param{fromZone} = $srcarea;
        $param{toZone}   = $dstarea;
        if ( not defined $param{srcIpRange} ) {
          $param{srcIpRange} = Firewall::Utils::Set->new( 0, 4294967295 );
        }
        if ( not defined $param{dstIpRange} ) {
          $param{dstIpRange} = Firewall::Utils::Set->new( 0, 4294967295 );
        }
        my $dyNat = Firewall::Config::Element::DynamicNat::Topsec->new(%param);
        $self->addElement($dyNat);
      }
    }
  }
  else {
    $self->warn("nat $string 分析不出来\n");
  }
} ## end sub parseNat

sub getvlanarea {
  my ( $self, $vlanName ) = @_;
  my $vlan = $self->getInterface($vlanName);

  #one vlan maybe not belong multi-area
  for my $phyInt ( keys %{$vlan->{interface}} ) {
    my $interface = $self->getInterface($phyInt);
    return $interface->{zoneName} if defined $interface;
  }
  return;
}

sub getZoneFromRange {
  my ( $self, $addrSet ) = @_;
  for my $route (
    grep { (
      ( defined $_->{type} and ( $_->{type} eq 'static' or $_->{type} eq 'connected' ) ) or not defined $_->{type} ) }
    sort { $b->mask <=> $a->mask } values %{$self->elements->route}
    )
  {
    if ( $route->range->isContain($addrSet) ) {
      return $route->zoneName;
    }
  }
  return;
}

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /ID\s+\d+\s+firewall\s+policy\s+add\s+action/i ) {
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
  my $rule = $self->getElement( 'rule', $policyId );
  return $rule;
}

sub parseRule {
  my ( $self, $string ) = @_;
  if (
    $string =~ /ID\s+(?<id>\d+)\s+firewall\s+policy\s+add\s+action\s+(?<action>\S+)\s+
        ((?<srca>srcarea|srcvlan)\s+'(?<srcareas>.+?)'\s+)?((?<dsta>dstarea|dstvlan)\s+'(?<dstareas>.+?)'\s+)?
        (src\s+'(?<src>.+?)'\s*)?(dst\s+'(?<dst>.+?)'\s*)?(service\s+'(?<srv>.+?)'\s*)?(schedule\s+(?<sch>\S+)\s*)?
        (sport\s+(?<sport>\S+)\s*)?(orig_dst\s+(?<origdst>\S+)\s*)?(dpi\s+(?<dpi>\S+)\s*)?
        (permanent\s+(?<perm>\S+)\s*)?(log\s+(?<log>\S+)\s*)?(enable\s+(?<enable>\S+)\s*)?/iox
    )
  {
    my %param;
    my ( %srcareas, %dstareas );
    my ( %srcVlan,  %dstVlan );
    my ( @srcs,     @dsts, @srvs );
    $param{ruleNum}   = $self->{ruleNum}++;
    $param{content}   = $string;
    $param{config}    = $string;
    $param{action}    = 'permit'  if $+{action} eq 'accept';
    $param{action}    = 'deny'    if $+{action} eq 'deny';
    $param{isDisable} = 'disable' if defined $+{enable} and $+{enable} eq 'no';
    $param{policyId}  = $+{id};

    if ( defined $+{srca} and $+{srca} eq 'srcarea' ) {
      map { $srcareas{$_} = undef } ( split '\s+', $+{srcareas} );
      $param{fromZone} = \%srcareas;
    }
    elsif ( defined $+{srca} and $+{srca} eq 'srcvlan' ) {
      my @srcvlans = split( '\s+', $+{srcareas} );
      map { $srcVlan{$_} = undef } @srcvlans;
      $param{fromVlan} = \%srcVlan;
      for my $vlanname (@srcvlans) {
        my $area = $self->getvlanarea($vlanname);
        $srcareas{$area} = undef if defined $area;
      }
    }
    if ( defined $+{dsta} and $+{dsta} eq 'dstarea' ) {
      map { $dstareas{$_} = undef } split( '\s+', $+{dstareas} );
      $param{toZone} = \%dstareas;
    }
    elsif ( defined $+{dsta} and $+{dsta} eq 'dstvlan' ) {
      my @dstvlans = split( '\s+', $+{dstareas} );
      map { $dstVlan{$_} = undef } @dstvlans;
      $param{toVlan} = \%dstVlan;
      for my $vlanname (@dstvlans) {
        my $area = $self->getvlanarea($vlanname);
        $dstareas{$area} = undef if defined $area;
      }
    }
    if ( defined $+{src} ) {
      @srcs = split( '\s+', $+{src} );
    }
    if ( defined $+{dst} ) {
      @dsts = split( '\s+', $+{dst} );
    }
    if ( defined $+{srv} ) {
      @srvs = split( '\s+', $+{srv} );
    }
    if ( defined $+{sch} ) {
      $param{schName} = $+{sch};
    }
    my $rule = Firewall::Config::Element::Rule::Topsec->new(%param);
    for my $srcadd (@srcs) {
      $self->addToRuleSrcAddressGroup( $rule, $srcadd );
    }
    for my $dstadd (@dsts) {
      $self->addToRuleDstAddressGroup( $rule, $dstadd );
    }
    for my $srv (@srvs) {
      $self->addToRuleServiceGroup( $rule, $srv );
    }
    if ( @srcs == 0 ) {
      if ( defined $+{srca} and $+{srca} eq 'srcvlan' ) {
        my @srcvlans = split( '\s+', $+{srcareas} );
        for my $vlan (@srcvlans) {
          $self->addToRuleSrcAddressGroup( $rule, $vlan, 'vlan' );
        }
      }
      else {
        $self->addToRuleSrcAddressGroup( $rule, 'any' );
      }
    }
    if ( @dsts == 0 ) {
      if ( defined $+{dsta} and $+{dsta} eq 'dstvlan' ) {
        my @dstvlans = split( '\s+', $+{dstareas} );
        for my $vlan (@dstvlans) {
          $self->addToRuleDstAddressGroup( $rule, $vlan, 'vlan' );
        }
      }
      else {
        $self->addToRuleDstAddressGroup( $rule, 'any' );
      }
    }
    if ( @srvs == 0 ) {
      $self->addToRuleServiceGroup( $rule, 'any' );
    }
    $self->addElement($rule);
  }
  else {
    $self->warn("rule $string 分析不出来\n");
  }
} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName, $type ) = @_;
  my $obj;
  if ( defined $type and $type eq 'vlan' ) {
    my $intVlan = $self->getInterface($srcAddrName);
    my ( $ip, $mask ) = ( $intVlan->{ipAddress}, $intVlan->{mask} );
    $obj = Firewall::Config::Element::Address::Topsec->new(
      addrName => $srcAddrName,
      ip       => $ip,
      mask     => $mask
    );
    $obj->addMember( {'ipmask' => $ip . "/$mask"} );
    $rule->addSrcAddressMembers( $srcAddrName, $obj );
    return;
  }
  if ( $srcAddrName =~ /^(?:Any)$/io ) {
    unless ( $obj = $self->getAddress($srcAddrName) ) {
      $obj = Firewall::Config::Element::Address::Topsec->new(
        addrName => $srcAddrName,
        ip       => '0.0.0.0',
        mask     => 0
      );
      $obj->addMember( {'ipmask' => "0.0.0.0/0"} );
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
  my ( $self, $rule, $dstAddrName, $type ) = @_;
  my $obj;
  if ( defined $type and $type eq 'vlan' ) {
    my $intVlan = $self->getInterface($dstAddrName);
    my ( $ip, $mask ) = ( $intVlan->{ipAddress}, $intVlan->{mask} );
    $obj = Firewall::Config::Element::Address::Topsec->new(
      addrName => $dstAddrName,
      ip       => $ip,
      mask     => $mask
    );
    $obj->addMember( {'ipmask' => $ip . "/$mask"} );
    $rule->addDstAddressMembers( $dstAddrName, $obj );
    return;
  }
  if ( $dstAddrName =~ /^(?:Any)$/io ) {
    unless ( $obj = $self->getAddress($dstAddrName) ) {
      $obj = Firewall::Config::Element::Address::Topsec->new(
        addrName => $dstAddrName,
        ip       => '0.0.0.0',
        mask     => 0
      );
      $obj->addMember( {'ipmask' => "0.0.0.0/0"} );
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
