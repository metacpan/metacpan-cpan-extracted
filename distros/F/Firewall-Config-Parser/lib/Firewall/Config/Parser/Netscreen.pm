package Firewall::Config::Parser::Netscreen;

use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 引用 Firewall::Config::Element::DynamicNat::Role 角色
#------------------------------------------------------------------------------
use Firewall::Config::Element::StaticNat::Netscreen;
use Firewall::Config::Element::NatPool::Netscreen;
use Firewall::Config::Element::DynamicNat::Netscreen;
use Firewall::Config::Element::Address::Netscreen;
use Firewall::Config::Element::AddressGroup::Netscreen;
use Firewall::Config::Element::Service::Netscreen;
use Firewall::Config::Element::ServiceGroup::Netscreen;
use Firewall::Config::Element::Schedule::Netscreen;
use Firewall::Config::Element::Rule::Netscreen;
use Firewall::Config::Element::Route::Netscreen;
use Firewall::Config::Element::Interface::Netscreen;
use Firewall::Config::Element::Zone::Netscreen;
use Firewall::Utils::Ip;
use Firewall::DBI::Pg;

with 'Firewall::Config::Parser::Role';

sub parse {
  my $self = shift;
  $self->{ruleNum} = 0;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isRoute($string) ) { $self->parseRoute($string) }
    elsif ( $self->isInterfaceZone($string) ) {
      $self->parseInterfaceZone($string);
    }
    elsif ( $self->isNatPool($string) ) {
      $self->parseNatPool($string);
    }

    #when ( $self->isActive($string)       ) { $self->setActive($string)         }
    else { $self->ignoreLine }
  }
  $self->addRouteToInterface;
  $self->addZoneRange;

  $self->goToHeadLine;
  while ( defined( my $string = $self->nextUnParsedLine ) ) {
    if    ( $self->isStaticNat($string) ) { $self->parseStaticNat($string) }
    elsif ( $self->isDynamicNat($string) ) {
      $self->parseDynamicNat($string);
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
    elsif ( $self->isSchedule($string) ) {
      $self->parseSchedule($string);
    }
    elsif ( $self->isRule($string) ) {
      $self->parseRule($string);
    }
    else {
      $self->ignoreLine;
    }
  } ## end while ( defined( my $string...))
  $self->{config} = "";
} ## end sub parse

sub isActive {
  my ( $self, $string ) = @_;
  if ( $string =~ /.+\(M|B\)->\s*/i ) {
    return 1;
  }
  else {
    return;
  }

}

sub setActive {
  my ( $self, $string ) = @_;
  if ( $string =~ /.+\((.+)\)->\s*/i ) {
    my $active = 1;
    my $backup = 0;
    $active = 0 if uc $1 eq 'B';
    $backup = 1 unless $active;
    my $fwId = $self->fwId;
    my $dbi  = Firewall::DBI::Pg->new(
      dsn      => 'dbi:Pg:host=ifsps.db.paic.com.cn;sid=ifsps;port=1534',
      user     => 'FWMSdata',
      password => 'CjN618thb'
    );
    my $sqlStr = "update fw_info set active = $active where fw_id = $fwId and (active <> $active or active is null)";
    my $sqlStr1
      = "update fw_info set active = $backup where group_id = (select group_id from fw_info where fw_id = $fwId )and fw_id <> $fwId";
    eval {
      $dbi->execute($sqlStr);
      $dbi->execute($sqlStr1);
    };
    if ($@) {
      confess "$@";
    }

  } ## end if ( $string =~ /.+\((.+)\)->\s*/i)

} ## end sub setActive

#set interface ethernet1/3.2 vip 210.21.223.59 25000 "5000" 192.168.170.228
#set interface ethernet1/3.2 vip 210.21.223.59 + 15000 "5000" 192.168.170.227

sub isDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /set\s+interface\s+\S+\s+vip/oxi ) {
    $self->setElementType('dynamicNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseDynamicNat {
  my ( $self, $string ) = @_;
  if ( $string
    =~ /set\s+interface\s+(?<interface>\S+)\s+vip\s+(?<natIp>\S+)\s+(\+\s+)?(?<natPort>\S+)\s+"(?<srv>\S+)"\s+(?<realIp>\S+)/oxi
    )
  {
    my %param;
    $param{config}     = $string;
    $param{fromZone}   = $self->getInterface( $+{interface} )->{zoneName};
    $param{toZone}     = $self->getZoneFromIp( $+{realIp}, 32 );
    $param{srcIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( '0.0.0.0',  '0' );
    $param{dstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{realIp}, '32' );
    my $serv = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{srv} );
    $param{srv}      = $serv;
    $param{srvRange} = $serv->range if defined $serv;
    my $protoNum = $serv->range->mins->[0] >> 16;
    $param{natSrvRange}   = Firewall::Utils::Ip->new->getRangeFromService("$protoNum/$+{natPort}");
    $param{natDstIp}      = $+{natIp};
    $param{natDstIpRange} = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natIp}, '32' );
    $param{natDirection}  = 'destination';
    $param{natDstPort}    = $+{natPort};
    $param{fwId}          = $self->fwId;
    my $dstip   = $+{natIp};
    my $address = Firewall::Config::Element::Address::Netscreen->new(
      fwId        => $self->fwId,
      addrName    => "VIP($dstip)",
      zone        => 'Global',
      ip          => $+{natIp},
      mask        => '32',
      description => 'vip'
    );
    $self->addElement($address);
    my $dynat = Firewall::Config::Element::DynamicNat::Netscreen->new(%param);
    $self->addElement($dynat);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseDynamicNat

sub isNatPool {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set\s+interface\s+\S+\s+(?:ext|dip)\s+/ox ) {
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
    $string =~ /^set\s+interface\s+(?<interface>\S+)
        (?:\s+ext\s+ip\s+(?<extIp>\d+\.\d+\.\d+\.\d+)\s+(?<extMask>\d+\.\d+\.\d+\.\d+))?
        \s+dip\s+(?<id>\d+)\s+(?<minIp>\d+\.\d+\.\d+\.\d+)\s+(?<maxIp>\d+\.\d+\.\d+\.\d+)(?: \s+ .+ )?\s*$/ox
    )
  {
    my $natPool = Firewall::Config::Element::NatPool::Netscreen->new(
      fwId          => $self->fwId,
      interfaceName => $+{interface},
      poolIp        => "$+{minIp}-$+{maxIp}",
      poolName      => $+{id},
      config        => $string
    );
    $self->addElement($natPool);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseNatPool

#set interface "ethernet0/0" zone "INS_DR"
#set interface ethernet0/0 ip 172.20.255.81/29
#set interface "ethernet0/1.1" tag 179 zone "DMZ-2"

sub isInterfaceZone {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ interface \s+ \S+ \s+ (tag\s+\S+\s+)* ((zone \s+\S+)|(ip \s+\d+\S+)) \s*/ox ) {
    $self->setElementType('interfaceZone');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }

}

sub addRouteToInterface {
  my $self           = shift;
  my $interfaceIndex = $self->elements->{interface};
  my $routeIndex     = $self->elements->{route};
  foreach my $interface ( values %{$interfaceIndex} ) {
    if ( defined $interface->{ipAddress} ) {
      foreach my $route ( values %{$routeIndex} ) {
        if ( defined $route->{nextHop} and $route->{type} eq 'static' ) {
          my $intIpSet   = Firewall::Utils::Ip->new->getRangeFromIpMask( $interface->{ipAddress}, $interface->{mask} );
          my $nextHopSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $route->{nextHop},       32 );
          if ( $intIpSet->isContain($nextHopSet) ) {
            $interface->addRoute($route);
            $route->{zoneName} = $interface->{zoneName};
          }
        }
      }
    }
  }
} ## end sub addRouteToInterface

sub addZoneRange {
  my $self = shift;
  foreach my $zone ( values %{$self->elements->{zone}} ) {
    foreach my $interface ( values %{$zone->interfaces} ) {
      $zone->range->mergeToSet( $interface->range );
    }
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

sub getZoneFromIp {
  my ( $self, $ip, $mask ) = @_;
  my $addrSet = Firewall::Utils::Ip->new->getRangeFromIpMask( $ip, $mask );
  for my $route (
    sort { $b->mask <=> $a->mask }
    grep { (
      ( defined $_->{type} and ( $_->{type} eq 'static' or $_->{type} eq 'connected' ) ) or not defined $_->{type} ) }
    values %{$self->elements->route}
    )
  {

    if ( $route->range->isContain($addrSet) ) {
      return $route->zoneName;
    }
  }

=pod
    my $zoneIndex = $self->elements->{zone};
    my $result;
    foreach my $zone (values %{$zoneIndex}) {
        if ($zone->range->isContain($ipSet)){
            $result=$zone->name;
             last;
        }

    }
=cut

} ## end sub getZoneFromIp

sub parseInterfaceZone {
  my ( $self, $string ) = @_;

=example
set interface "ethernet0/0" zone "INS_DR"
set interface ethernet0/0 ip 172.20.255.81/29
=cut

  if (
    $string =~ /^set \s+ interface \s+
        "(?<interfaceName>[^"]+)" \s+ (tag\s+\S+\s+)*
        zone \s+ "(?<zoneName>[^"]+)"
        \s*$/ox
    )
  {
    my $interface;
    if ( not defined( $interface = $self->getInterface( $+{interfaceName} ) ) ) {
      $interface = Firewall::Config::Element::Interface::Netscreen->new(
        fwId     => $self->fwId,
        name     => $+{interfaceName},
        zoneName => $+{zoneName},
        config   => $string
      );
      $self->addElement($interface);
    }
    else {
      $interface->{config} .= "\n" . $string;
    }

    my $zone;
    if ( not defined( $zone = $self->getZone( $+{zoneName} ) ) ) {
      $zone = Firewall::Config::Element::Zone::Netscreen->new(
        fwId   => $self->fwId,
        name   => $+{zoneName},
        config => $string
      );
      $self->addElement($zone);
    }
    $zone->addInterface($interface);

  }
  elsif ( $string =~ /^set \s+ interface \s+ (?<interfaceName>\S+)\s+ ip \s+ (?<ipMask>\d+\.\d+\.\d+\.\d+\S+) \s*$/ox )
  {
    my $interface;
    my ( $ipAddress, $mask ) = split( '/', $+{ipMask} );
    if ( not defined( $interface = $self->getInterface( $+{interfaceName} ) ) ) {
      $interface = Firewall::Config::Element::Interface::Netscreen->new(
        fwId   => $self->fwId,
        name   => $+{interfaceName},
        config => $string
      );
      $self->addElement($interface);
    }
    else {
      $interface->{config} .= "\n" . $string;
    }
    $interface->{interfaceType} = 'layer3';
    $interface->{ipAddress}     = $ipAddress;
    $interface->{mask}          = $mask;
    my $route = Firewall::Config::Element::Route::Netscreen->new(
      fwId    => $self->fwId,
      network => $ipAddress,
      mask    => $mask,
      type    => 'static'
    );
    $route->{zoneName} = $interface->{zoneName};
    $interface->addRoute($route);
    $self->addElement($route);
  }
  elsif ( $string
    =~ /^set \s+ interface \s+ (?<interfaceName>\S+)\s+ ip \s+ (?<ipMask>\d+\.\d+\.\d+\.\d+\s+\d+\.\d+\.\d+\.\d+)\s+ secondary\s*$/ox
    )
  {
    my $interface;
    my ( $ipAddress, $mask ) = split( '\s+', $+{ipMask} );
    if ( not defined( $interface = $self->getInterface( $+{interfaceName} ) ) ) {
      $interface = Firewall::Config::Element::Interface::Netscreen->new(
        fwId   => $self->fwId,
        name   => $+{interfaceName},
        config => $string
      );
      $self->addElement($interface);
    }
    else {
      $interface->{config} .= "\n" . $string;
    }
    $mask = Firewall::Utils::Ip->new->changeMaskToNumForm($mask);
    my $route = Firewall::Config::Element::Route::Netscreen->new(
      fwId    => $self->fwId,
      network => $ipAddress,
      mask    => $mask,
      nextHop => $ipAddress
    );
    $route->{zoneName} = $interface->{zoneName};
    $interface->addRoute($route);
    $self->addElement($route);

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseInterfaceZone

#set route 10.0.0.0/8 interface ethernet0/0 gateway 10.37.172.200 preference 20
#set route source 10.88.138.41/32 interface ethernet0/2.1 gateway 113.140.11.129
sub isRoute {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ route \s+(source\s+)? \S+ \s+ (interface \s+ \S+ \s+)* /ox ) {
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

=example
set route 10.0.0.0/8 interface ethernet0/2 gateway 10.36.254.62
set route 172.20.24.0/22 gateway 172.20.255.86
=cut

  if (
    $string =~ /^set \s+ route \s+
        (?<networkMask>\S+) \s+
        (interface \s+ (?<name>\S+)\s+)*
        gateway \s+ (?<nextHop>\S+)
        \s*/ox
    )
  {
    my ( $network, $mask ) = split( '/', $+{networkMask} );
    my $nextHop = $+{nextHop};
    my $intName = $+{name};
    return if $network !~ /\d+\.\d+\.\d+\.\d+/;    #maybe ipv6 not support now
    my $route = Firewall::Config::Element::Route::Netscreen->new(
      fwId    => $self->fwId,
      network => $network,
      mask    => $mask,
      nextHop => $nextHop,
      config  => $string
    );
    if ( defined $intName ) {
      my $interface = $self->getInterface($intName);
      $route->{zoneName} = $interface->{zoneName};
    }

    $self->addElement($route);
  }
  elsif (
    $string =~ /^set \s+ route \s+
        (?<networkMask>\S+) \s+
        interface \s+ (?<name>\S+)\s*
    /ox
    )
  {
    my ( $network, $mask ) = split( '/', $+{networkMask} );
    my $route = Firewall::Config::Element::Route::Netscreen->new(
      fwId    => $self->fwId,
      network => $network,
      mask    => $mask,
      config  => $string
    );
    my $interface = $self->getInterface( $+{name} );

    $interface->addRoute($route);
    $route->{zoneName} = $interface->{zoneName};
    $self->addElement($route);
  }
  elsif (
    $string =~ /set\s+route\s+source\s+(?<source>\S+)(\s+interface\s+(?<intName>\S+))?\s+gateway\s+(?<nextHop>\S+)/ )
  {
    my %param;
    $param{type}      = 'policy';
    $param{srcIpmask} = $+{source};
    $param{nextHop}   = $+{nextHop};
    $param{network}   = '0.0.0.0';
    $param{mask}      = 0;
    $param{config}    = $string;
    my $route = Firewall::Config::Element::Route::Netscreen->new(%param);
    $self->addElement($route);
    my $interface = $self->getInterface( $+{intName} );
    $route->{zoneName} = $interface->{zoneName};

  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseRoute

sub isStaticNat {
  my ( $self, $string ) = @_;
  if ( $string =~ /set \s+ interface \s+ "[^"]+" \s+ mip \s+/ox ) {
    $self->setElementType('staticNat');
    return 1;
  }
  else {
    $self->setElementType();
    return;
  }
}

sub parseStaticNat {
  my ( $self, $string ) = @_;

=example
set interface "ethernet0/0" mip 10.37.172.25 host 192.168.184.25 netmask 255.255.255.255 vr "trust-vr"
=cut

  if (
    $string =~ /^set \s+ interface
        \s+
        "(?<interface>[^"]+)"
        \s+
        mip
        \s+
        (?<natIp>\d+\.\d+\.\d+\.\d+)
        \s+
        host
        \s+
        (?<realIp>\d+\.\d+\.\d+\.\d+)
        \s+
        netmask
        \s+
        (?<mask>\d+\.\d+\.\d+\.\d+)
        (?:\s+ vr \s+ (?<vr>\S+))?
        \s*$/ox
    )
  {
    my %param;
    $param{config}       = $string;
    $param{fwId}         = $self->fwId;
    $param{natInterface} = $+{interface};
    $param{natZone}      = $self->getInterface( $+{interface} )->{zoneName};
    $param{mask}         = Firewall::Utils::Ip->new->changeMaskToNumForm( $+{mask} );
    $param{realZone}     = $self->getZoneFromIp( $+{realIp}, $+{mask} );
    $param{realIp}       = $+{realIp};
    $param{realIpRange}  = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{realIp}, $+{mask} );
    $param{natIp}        = $+{natIp};
    $param{natIpRange}   = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{natIp}, $+{mask} );
    my $staticNat = Firewall::Config::Element::StaticNat::Netscreen->new(%param);
    $self->addElement($staticNat);

    if ( $param{mask} == 32 ) {
      my $address = Firewall::Config::Element::Address::Netscreen->new(
        fwId        => $self->fwId,
        addrName    => "MIP($+{natIp})",
        zone        => 'Global',
        ip          => $+{natIp},
        mask        => $param{mask},
        description => 'mip'
      );
      $self->addElement($address);
    }
    else {
      my $maskNum = Firewall::Utils::Ip->new->changeMaskToNumForm( $param{mask} );
      my $address = Firewall::Config::Element::Address::Netscreen->new(
        fwId        => $self->fwId,
        addrName    => "MIP($+{natIp}/$maskNum)",
        zone        => 'Global',
        ip          => $+{natIp},
        mask        => $param{mask},
        description => 'mip'
      );
      $self->addElement($address);
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseStaticNat

sub isAddress {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ address \s+/ox ) {
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
  $zone = 'Global' if $addrName =~ /^MIP\(.+\)$/;
  return $self->getElement( 'address', $zone, $addrName );
}

sub parseAddress {
  my ( $self, $string ) = @_;

=example
set address "V1-Untrust" "Host_10.29.38.10" 10.29.38.10 255.255.255.255 "hsh-1219"
=cut

  if (
    $string =~ /^set \s+ address
        \s+
        "(?<zone>[^"]+)"
        \s+
        "(?<addrName>[^"]+)"
        \s+
        (?<ip>\d+\.\d+\.\d+\.\d+)
        \s+
        (?<mask>\d+\.\d+\.\d+\.\d+)
        (?:\s+"(?<description>[^"]+)")?
        \s*$/ox
    )
  {
    my $address = Firewall::Config::Element::Address::Netscreen->new(
      fwId        => $self->fwId,
      addrName    => $+{addrName},
      zone        => $+{zone},
      ip          => $+{ip},
      mask        => $+{mask},
      description => $+{description},
      config      => $string
    );
    $self->addElement($address);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseAddress

sub isAddressGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ group \s+ address \s+/ox ) {
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
set group address "V1-Trust" "g_cache_server" comment " "
set group address "V1-Trust" "A_LINUX_DNS_2012"
set group address "V1-Trust" "A_LINUX_DNS_2012" add "H_10.31.120.1"
set group address "V1-Trust" "A_LINUX_DNS_2012" add "H_10.31.120.2"
=cut

  if (
    $string =~ /^set \s+ group \s+ address
        \s+
        "(?<zone>[^"]+)"
        \s+ "(?<addrGroupName>[^"]+)"
        (?:\s+comment\s+"(?<description>[^"]+)")?
        \s*$/ox
    )
  {
    my $addressGroup = Firewall::Config::Element::AddressGroup::Netscreen->new(
      fwId          => $self->fwId,
      addrGroupName => $+{addrGroupName},
      zone          => $+{zone},
      description   => $+{description},
      config        => $string
    );
    $self->addElement($addressGroup);
  }
  elsif (
    $string =~ /^set \s+ group \s+ address
        \s+
        "(?<zone>[^"]+)"
        \s+
        "(?<addrGroupName>[^"]+)"
        \s+
        add
        \s+
        "(?<addrGroupMemberName>[^"]+)"
        \s*$/ox
    )
  {
    my $addressGroup;
    if ( $addressGroup = $self->getAddressGroup( $+{zone}, $+{addrGroupName} ) ) {
      $addressGroup->{config} .= "\n" . $string;
      my $obj = $self->getAddressOrAddressGroupFromAddrGroupMemberName( $+{zone}, $+{addrGroupMemberName} );
      if ( not defined $obj ) {
        $self->warn(
          "addrGroup $+{addrGroupName} 的 addrGroupMember $+{addrGroupMemberName} 既不是 address 也不是 addressGroup\n");
      }
      $addressGroup->addAddrGroupMember( $+{addrGroupMemberName}, $obj );

    }
    else {
      $self->warn("$string 缺少声明行\n");
    }
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseAddressGroup

sub getAddressOrAddressGroupFromAddrGroupMemberName {
  my ( $self, $zone, $addrGroupMemberName ) = @_;
  my $obj = $self->getAddress( $zone, $addrGroupMemberName ) // $self->getAddressGroup( $zone, $addrGroupMemberName )
    // $self->getAddress( 'Global', $addrGroupMemberName ) // $self->getAddressGroup( 'Global', $addrGroupMemberName );
  return $obj;
}

sub isService {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ service \s+/ox ) {
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
  my $sign = Firewall::Config::Element::Service::Netscreen->createSign($srvName);
  return ( $self->preDefinedService->{$sign} );
}

sub parseService {
  my ( $self, $string ) = @_;

=example
set service "TCP/UDP_42430" protocol tcp src-port 0-65535 dst-port 42430-42430
set service "TCP/UDP_42430" + udp src-port 0-65535 dst-port 42430-42430
set service "TCP/UDP_42430" timeout never
set service "TEST_1534" protocol tcp src-port 0-65535 dst-port 1534-1534 timeout 720
set service "my-sunrpc-nfs" protocol sun-rpc program 100003-100003
set service "my-sunrpc-nfs" + sun-rpc program 100227-100227
=cut

  if (
    $string =~ /^set \s+ service
        \s+
        "(?<srvName>[^"]+)"
        \s+
        protocol
        \s+
        (?<protocol>\w+)
        \s+
        src-port
        \s+
        (?<srcPort>\d+-\d+)
        \s+
        dst-port
        \s+
        (?<dstPort>\d+-\d+)
        (?:\s+timeout\s+(?<timeout>\w+))?
        \s*$/ox
    )
  {
    my $service = Firewall::Config::Element::Service::Netscreen->new(
      fwId     => $self->fwId,
      srvName  => $+{srvName},
      protocol => $+{protocol},
      srcPort  => $+{srcPort},
      dstPort  => $+{dstPort},
      timeout  => $+{timeout}
    );
    $service->{config} = $string;
    $self->addElement($service);
  }
  elsif (
    $string =~ /^set \s+ service
        \s+
        "(?<srvName>[^"]+)"
        \s+
        \+
        \s+
        (?<protocol>\w+)
        \s+
        src-port
        \s+
        (?<srcPort>\d+-\d+)
        \s+
        dst-port
        \s+
        (?<dstPort>\d+-\d+)
        (?:\s+timeout\s+(?<timeout>\w+))?
        \s*$/ox
    )
  {
    my $service;
    if ( $service = $self->getService( $+{srvName} ) ) {
      $service->{config} .= "\n" . $string;
      $service->addMeta(
        fwId     => $self->fwId,
        srvName  => $+{srvName},
        protocol => $+{protocol},
        srcPort  => $+{srcPort},
        dstPort  => $+{dstPort},
        timeout  => $+{timeout}
      );
    }
    else {
      $self->warn("$string 缺少预定义行\n");
    }
  }
  elsif ( $string =~ /^set \s+ service \s+ "(?<srvName>[^"]+)" \s+ timeout \s+ (?<timeout>\w+) \s*$/ox ) {
    my $service;
    if ( $service = $self->getService( $+{srvName} ) ) {
      $service->setTimeout( $+{timeout} );
      $service->{config} .= "\n" . $string;
    }
    elsif ( $self->getPreDefinedService( $+{srvName} ) ) {
      if ( my $service = $self->getService( $+{srvName} ) ) {
        $service->{config} .= "\n" . $string;
      }
    }
    else {
      $self->warn("$string 缺少预定义行\n");
    }
  }
  elsif ( $string =~ /^set \s+ service \s+ "[^"]+" \s+ (?:protocol|\+) \s+ \S+ \s+ program \s+ \d+-\d+ \s*$/ox ) {

    #忽略这种情况
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseService

sub isServiceGroup {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ group \s+ service \s+/ox ) {
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
set group service "BKUP_SERVICES" comment " "
set group service "BKUP_SERVICES" add "TCP/UDP_26213"
set group service "BKUP_SERVICES" add "TCP/UDP_26214"
set group service "BKUP_SERVICES" add "TCP/UDP_26238"
set group service "BKUP_SERVICES" add "TCP/UDP_26470"
set group service "BKUP_SERVICES" add "TCP/UDP_26726"
set group service "BKUP_SERVICES" add "TCP/UDP_26982"
set group service "BKUP_SERVICES" add "TCP/UDP_27238"
=cut

  if (
    $string =~ /^set \s+ group \s+ service
        \s+
        "(?<srvGroupName>[^"]+)"
        (?:\s+comment\s+"(?<description>[^"]+)")?
        \s*$/ox
    )
  {
    my $serviceGroup = Firewall::Config::Element::ServiceGroup::Netscreen->new(
      fwId         => $self->fwId,
      srvGroupName => $+{srvGroupName},
      description  => $+{description},
      config       => $string
    );
    $self->addElement($serviceGroup);
  }
  elsif (
    $string =~ /^set \s+ group \s+ service
        \s+
        "(?<srvGroupName>[^"]+)"
        \s+
        add
        \s+
        "(?<srvGroupMemberName>[^"]+)"
        \s*$/ox
    )
  {
    my $serviceGroup;
    if ( $serviceGroup = $self->getServiceGroup( $+{srvGroupName} ) ) {
      $serviceGroup->{config} .= "\n" . $string;
      my $obj = $self->getServiceOrServiceGroupFromSrvGroupMemberName( $+{srvGroupMemberName} );
      if ( not defined $obj ) {
        $self->warn(
          "srvGroup $+{srvGroupName} 的 srvGroupMember $+{srvGroupMemberName} 既不是 service 不是 pre-defined service 也不是 service Group\n"
        );
      }
      $serviceGroup->addSrvGroupMember( $+{srvGroupMemberName}, $obj );

    }
    else {
      $self->warn("$string 缺少声明行\n");
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
  if ( $string =~ /^set \s+ scheduler \s+/ox ) {
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
set scheduler "S_20120331" once start 10/10/2011 0:0 stop 3/31/2012 23:59
set scheduler "S20110630" recurrent friday start 10:00 stop 12:00 start 14:00 stop 16:00 comment "test"
=cut

  if (
    $string =~ /^set \s+ scheduler
        \s+
        "(?<schName>[^"]+)"
        \s+
        (?<schType>once)
        \s+
        start
        \s+
        (?<startDate>.+?)
        \s+
        stop
        \s+
        (?<endDate>.+?)
        \s*$/ox
    )
  {
    my $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
      fwId      => $self->fwId,
      schName   => $+{schName},
      schType   => $+{schType},
      startDate => $+{startDate},
      endDate   => $+{endDate},
      config    => $string
    );
    $self->addElement($schedule);
  }
  elsif (
    $string =~ /^set \s+ scheduler
        \s+
        "(?<schName>[^"]+)"
        \s+
        (?<schType>recurrent)
        \s+
        (?<weekday>\w+)
        \s+
        start
        \s+
        (?<startTime1>.+?)
        \s+
        stop
        \s+
        (?<endTime1>.+?)
        \s+
        start
        \s+
        (?<startTime2>.+?)
        \s+
        stop
        \s+
        (?<endTime2>.+?)
        (?:\s+comment\s+"(?<description>[^"]+)")?
        \s*$/ox
    )
  {
    my $schedule = Firewall::Config::Element::Schedule::Netscreen->new(
      fwId        => $self->fwId,
      schName     => $+{schName},
      schType     => $+{schType},
      weekday     => $+{weekday},
      startTime1  => $+{startTime1},
      endTime1    => $+{endTime1},
      startTime2  => $+{startTime2},
      endTime2    => $+{endTime2},
      description => $+{description}
    );
    $self->addElement($schedule);
  }
  else {
    $self->warn("$string 分析不出来\n");
  }
} ## end sub parseSchedule

sub getDynamicNat {
  my ( $self, $policyId ) = @_;
  return $self->getElement( 'dynamicNat', $policyId );
}

sub isRule {
  my ( $self, $string ) = @_;
  if ( $string =~ /^set \s+ policy \s+ id \s+ \d+ \s+ (from|name)/ox ) {
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
  return $self->getElement( 'rule', $policyId );
}

sub parseRule {
  my ( $self, $string ) = @_;

=example
set policy id 697 from "Trust" to "Global"  "Host_10.8.35.88" "MIP(10.37.174.134)" "S_BIB-TPDS_never" permit log sess-limit per-src-ip 3200
exit
set policy id 1096 name "459646" from "DMZ-2" to "Untrust"  "BCAP-FXMS-AIO-FRONT-RTNS" "PN-REUTER-DOWNLOAD" "HTTPS" nat src permit
exit
set policy id 1840 from "DMZ-2" to "Untrust"  "Host_192.168.177.53" "Host_9.234.250.43" "TCP_60206" nat src dip-id 79 permit
exit
set policy id 1830 from "Untrust" to "DMZ-2"  "Host_13.168.10.41" "Host_172.16.41.21" "TCP_8007" nat dst ip 192.168.188.21 permit log
exit
set policy id 335 from "Untrust" to "Untrust"  "Host_199.100.101.21" "Host_172.41.1.21" "TCP_30110" nat dst ip 172.40.16.42 port 8007 permit log count
exit
set policy id 1773 from "Untrust" to "DMZ-2"  "XieCheng_10.2.254.17" "Host_172.16.41.21" "SSH" nat src dip-id 109 dst ip 192.168.188.21 permit log
exit
set policy id 1347 from "Trust" to "Untrust"  "Host_172.40.13.57" "Host_172.27.16.16" "SSH" nat src dip-id 38 dst ip 172.27.16.16 port 1688 permit log
exit
set policy id 4090 name "781515" from "V1-Untrust" to "V1-Trust"  "Host_10.25.118.40" "Host_10.31.9.63" "SSH" permit log
exit
set policy id 4227 from "V1-Untrust" to "V1-Trust"  "Host_10.65.1.137" "Host_10.31.102.117" "TCP_1521" permit schedule "S20131227" log
set policy id 4227
set src-address "Host_10.65.1.152"
set dst-address "Host_10.31.9.81"
set service "tcp_3389"
set service "tcp_5901"
set log session-init
exit
set policy id 1551 from "Untrust" to "Trust"  "G_Windows_Svr" "G_OA_DC_Server" "G_OA_DC_Service" permit log count
set policy id 1551
exit
=cut

  my $policyId;
  do {
    if (
      $string =~ /^set \s+ policy \s+ id
            \s+
            (?<policyId>\d+)
            (?:\s+name\s+"(?<alias>[^"]+)")?
            \s+
            from
            \s+
            "(?<fromZone>[^"]+)"
            \s+
            to
            \s+
            "(?<toZone>[^"]+)"
            \s+
            "(?<srcAddrName>[^"]+)"
            \s+
            "(?<dstAddrName>[^"]+)"
            \s+
            "(?<srvName>[^"]+)"
            (?<other>.+)
            \s*$/ox
      )
    {

      $policyId = $+{policyId};
      if ( $self->getRule($policyId) ) {
        $self->warn("id 为 $policyId 的 rule 的声明出现了两次\n");
        return;
      }
      my ( $alias, $fromZone, $toZone, $srcAddrName, $dstAddrName, $srvName, $other )
        = @{+}{qw/ alias fromZone toZone srcAddrName dstAddrName srvName other /};
      if (
        $other =~ /^
                (\s+ nat
                (\s+ src
                (\s+ dip-id \s+ (?<poolName>\S+))?
                )?
                (\s+ dst \s+ ip \s+ (?<dstIp>\S+) (\s+ port \s+ (?<natPort>\d+))? )?
                )?
                \s+
                (?<action>\w+)
                (?:\s+schedule\s+"(?<schName>[^"]+)")?
                (?:\s+(?<hasLog>log)
                (?:\s+ count)?
                (?:\s+ sess-limit \s+ per-src-ip \s+ \d+)?
                )?
                \s*/ox
        )
      {

        my $rule = Firewall::Config::Element::Rule::Netscreen->new(
          ruleNum  => $self->{ruleNum}++,
          fwId     => $self->fwId,
          policyId => $policyId,
          alias    => $alias,
          fromZone => $fromZone,
          toZone   => $toZone,
          action   => $+{action},
          schName  => $+{schName},
          hasLog   => $+{hasLog},
          content  => $string,
          priority => $self->lineNumber
        );
        if ( defined $+{schName} ) {
          if ( my $schedule = $self->getSchedule( $+{schName} ) ) {
            $rule->setSchedule($schedule);
          }
          else {
            $self->warn("schName $+{schName} 不是 schedule\n");
          }
        }
        if ( defined $+{poolName} or defined $+{dstIp} ) {
          my $natDirection = ( defined $+{poolName} ? 'source' : '' ) . ( defined $+{dstIp} ? 'destination' : '' );
          my $natSrcPool;
          my $natSrcIpRange;
          my $natDstIpRange;

          #my $dstIpRange;
          if ( defined $+{dstIp} ) {
            $natDstIpRange = Firewall::Utils::Ip->new->getRangeFromIpMask( $+{dstIp} );
          }
          if ( defined $+{poolName} ) {
            $natSrcPool = $self->getNatPool( $+{poolName} );
            if ( not defined $natSrcPool ) {
              confess("防火墙ID $self->fwId 的pool dip $+{poolName}未分析完整");
            }
            $natSrcIpRange = $natSrcPool->poolRange;
          }
          my %natParam;
          $natParam{fwId}          = $self->fwId;
          $natParam{policyId}      = $policyId;
          $natParam{fromZone}      = $fromZone;
          $natParam{toZone}        = $toZone;
          $natParam{natDirection}  = $natDirection;
          $natParam{natSrcPool}    = $natSrcPool;
          $natParam{natSrcIpRange} = $natSrcIpRange;
          $natParam{config}        = $string;
          $natParam{dstIpRange}    = $natDstIpRange if defined $natDstIpRange;    #目的nat，nat之后的为真实地址

          if ( defined $+{natPort} ) {

            #realPort
            $natParam{srvRange} = Firewall::Utils::Ip->new->getRangeFromService("tcp/$+{natPort}");

          }
          my $dynamicNat = Firewall::Config::Element::DynamicNat::Netscreen->new(%natParam);
          $self->addElement($dynamicNat);
        } ## end if ( defined $+{poolName...})

        $self->addElement($rule);
        my $index = $fromZone . $toZone;
        push @{$self->{ruleIndex}{$index}}, $rule;
        $self->addToRuleSrcAddressGroup( $rule, $srcAddrName );
        $self->addToRuleDstAddressGroup( $rule, $dstAddrName );
        $self->addToRuleServiceGroup( $rule, $srvName );
      }
      else {
        $policyId = undef;
        $self->warn("声明行 [$string] 分析失败\n");
      }

    }
    elsif ( not defined $policyId ) {
      $self->warn("本行 [$string] 所在的rule的声明行分析失败\n");
    }
    else {
      my $rule = $self->getRule($policyId);
      $rule->addContent($string);
      my $dynamicNat = $self->getDynamicNat($policyId);
      if ( defined $dynamicNat ) {
        $dynamicNat->{config} .= "\n" . $string;
      }
      if ( $string =~ /^set \s+ policy \s+ id \s+ $policyId \s+ (?<isDisable>disable) \s*$/x ) {
        $rule->setIsDisable( $+{isDisable} );
      }
      elsif ( $string =~ /^set \s+ policy \s+ id \s+ $policyId \s+ application \s+ "(?<applicationCheck>[^"]+)" \s*$/x )
      {
        $rule->setHasApplicationCheck( $+{applicationCheck} );
      }
      elsif ( $string =~ /^set \s+ policy \s+ id \s+ $policyId \s*$/x ) {
      }
      elsif ( $string =~ /^set \s+ src-address \s+ "(?<srcAddrName>[^"]+)" \s*$/ox ) {
        $self->addToRuleSrcAddressGroup( $rule, $+{srcAddrName} );
      }
      elsif ( $string =~ /^set \s+ dst-address \s+ "(?<dstAddrName>[^"]+)" \s*$/ox ) {
        $self->addToRuleDstAddressGroup( $rule, $+{dstAddrName} );
      }
      elsif ( $string =~ /^set \s+ service \s+ "(?<srvName>[^"]+)" \s*$/ox ) {
        $self->addToRuleServiceGroup( $rule, $+{srvName} );
      }
      elsif ( $string =~ /^set \s+ log \s+ session-init \s*$/ox ) {

        #暂时忽略
      }
      elsif ( $string =~ /^exit\s*$/o ) {
        my $dynamicNat = $self->getDynamicNat($policyId);
        if ( defined $dynamicNat ) {
          $dynamicNat->{srcIpRange} = $rule->srcAddressGroup->range;
          if ( $dynamicNat->natDirection eq 'destination' ) {
            $dynamicNat->{natDstIpRange} = $rule->dstAddressGroup->range;
          }
          else {
            $dynamicNat->{dstIpRange} = $rule->dstAddressGroup->range;
          }
          if ( defined $dynamicNat->{srvRange} ) {
            $dynamicNat->{natSrvRange} = $rule->serviceGroup->range;
          }
          else {
            $dynamicNat->{srvRange} = $rule->serviceGroup->range;
          }
        }
        return;
      }
      else {
        $self->warn("id 为 $policyId 的行 [$string] 分析不出来\n");
      }
    } ## end else [ if ( $string =~ /^set \s+ policy \s+ id )]
  } while ( $string = $self->nextUnParsedLine );
} ## end sub parseRule

sub addToRuleSrcAddressGroup {
  my ( $self, $rule, $srcAddrName ) = @_;

  my $obj;
  if ( $srcAddrName =~ /^Any$|any-ipv4/io ) {
    unless ( $obj = $self->getAddress( $rule->fromZone, $srcAddrName ) ) {
      $obj = Firewall::Config::Element::Address::Netscreen->new(
        fwId     => $self->fwId,
        addrName => $srcAddrName,
        ip       => '0.0.0.0',
        mask     => '0.0.0.0',
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
  if ( $dstAddrName =~ /^Any$|Any-IPv4/io ) {
    unless ( $obj = $self->getAddress( $rule->toZone, $dstAddrName ) ) {
      $obj = Firewall::Config::Element::Address::Netscreen->new(
        fwId     => $self->fwId,
        addrName => $dstAddrName,
        ip       => '0.0.0.0',
        mask     => '0.0.0.0',
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
