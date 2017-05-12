package Device::ZyXEL::IES::Port;
use Moose;
use Net::SNMP qw/:asn1 ticks_to_time/;
use Net::SNMP::Util qw/snmpget/;
use namespace::autoclean;
use Device::ZyXEL::IES::OID;

=head1 NAME

Device::ZyXEL::IES::Port - A model of a Port on a Slot on an IES.

=head1 VERSION

Version 0.10

=cut

our $VERSION = '0.10';

=head1 SYNOPSIS

Models a port on a ZyXEL IES Device.

Based on Moose.

# Must have a Device::Zyxel::IES::Slot object

my $p = Device::ZyXEL::IES::Port(
  id => 301, slot => $s );

my $adminstatus = $p->read_adminstatus();

# $adminstatus is now the same as $p->adminstatus();

# DOWN the port

$p->adminstatus(1); 

=head1 MOOSE ATTRIBUTES

=head2 id

Required attribute that identifies the port. Matches ifIndex.

=cut

has 'id' => (
  isa => 'Int', 
  is => 'ro', 
  required => 1
);

=head2 slot

Required attribute that isa Device::ZyXEL::IES::Slot object.

=cut
has 'slot' => (
	isa => 'Device::ZyXEL::IES::Slot', 
	is => 'ro', 
	required => 1
);

=head2 adminstatus (rw)

ifAdminStatus on the port. Read from IES using read_adminstatus

=cut
has 'adminstatus' => (
  isa => 'Int', 
  is => 'rw',
);

=head2 operstatus (ro)

ifOperStatus on the port. Read from IES using read_operstatus

=cut
has 'operstatus' => (
  isa => 'Int', 
  is => 'ro', 
  default => sub {0}, 
  writer => '_set_operstatus'
);

=head2 uptime (ro)

uptime on the port. Read from IES using read_uptime

=cut
has 'uptime' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_uptime'
);

=head2 profile (rw)

Configuration profile on the port. This attribute OID will depend on the 
type of xDSL interface of the port.

=cut
has 'profile' => (
  isa => 'Str', 
  is => 'rw', 
  default => sub {''}
);

=head2 ifInOctets (ro)

the ifInOctets on the port. Note that if this conglomorate of modules 
is used to systematically read and record (say using RRD) values,  you
might expience trouble with cpu load on the IES. (See Device::ZyXEL::IES)

Retrieve a value for this attribute from the IES using read_ifInOctets
=cut
has 'ifInOctets' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifInOctets'
);

=head2 ifOutOctets (ro)

the ifOutOctets on the port. Note that if this conglomorate of modules 
is used to systematically read and record (say using RRD) values,  you
might expience trouble with cpu load on the IES. (See Device::ZyXEL::IES)

Retrieve a value for this attribute from the IES using read_ifOutOctets
=cut
has 'ifOutOctets' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifOutOctets'
);

=head2 userinfo (ro)

Contains the userinfo OID value from the IES.

Retrieve userinfo from the IES Port using read_userinfo
=cut
has 'userinfo' => (
  isa => 'Str', 
  is => 'ro', 
  writer => '_set_userinfo'
);

=head2 ifLastChange (ro)

Contains the ifLastChange OID value from the IES.

Retrieve a value from the IES Port using read_ifLastChange.

This attribute can be used to calculate the uptime of the port.
=cut
has 'ifLastChange' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_ifLastChange'
);

=head2 maxmac (rw)

Contains the maxmac setting from the IES.

Retrieve the maxmac value from the IES Port using read_maxmac, 
before that the value of this attribute will not reflect reality.

The maxmac setting is used by the IES in conjunction with the Snoop
feature to ensure a maximum number of MAC address pr port.

=cut
has 'maxmac' => (
  isa => 'Int', 
  is => 'rw', 
  lazy => 1, 
  default => sub { 2 }
);

=head2 maxdown (ro)

Contains the maxAttainableDownstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'maxdown' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_maxdown'
);

=head2 maxup (ro)

Contains the maxAttainableUpstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'maxup' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_maxup'
);

=head2 downspeed (ro)

Contains the currAttainableDownstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'downspeed' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_downspeed'
);

=head2 upspeed (ro)

Contains the currAttainableUpstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'upspeed' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_upspeed'
);

=head2 snr_down (ro)

Contains the SNR on the Downstream channel from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'snr_down' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_snrdown'
);

=head2 snr_up (ro)

Contains the SNR on the Upstream channel from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'snr_up' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_snrup'
);

=head2 atn_down (ro)

Contains the current Attenautaion Downstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'atn_down' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_atndown'
);

=head2 atn_up (ro)

Contains the current Attenautaion Upstream setting from the IES.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'atn_up' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_atnup'
);

=head2 inp_down (rw)

Contains the current impulse noise protection level on the Downstream channel.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'inp_down' => (
  isa => 'Int', 
  is => 'rw'
);

=head2 inp_up (rw)

The upstream Impulse Noise Protection minimum setting in unit of DMT symbol.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'inp_up' => (
  isa => 'Int', 
  is => 'rw'
);

=head2 annexM (rw)

The ADSL Annex M setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'annexM' => (
  isa => 'Int', 
  is => 'rw', 
  default => sub {0}
);

=head2 annexL (rw)

The ADSL Annex L setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'annexL' => (
  isa => 'Int', 
  is => 'rw', 
  default => sub {0}
);

=head2 wirepairmode (ro)

The S.HDSL Wirepair Mode setting.

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'wirepairmode' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_wirepairmode'
);


=head2 vdslprotocol (ro)

The VDSL Protocol Mode setting.

One of

 none(1), 
 vdsl_8a(2), 
 vdsl_8b(3), 
 vdsl_8c(4), 
 vdsl_8d(5), 
 vdsl_12a(6), 
 vdsl_12b(7), 
 vdsl_17a(8), 
 vdsl_30a(9), 
 adsl2plus(10)

This attribute depends on the interface type, as determined by the assiciated Device::ZyXEL::IES::Slot 
object.

=cut
has 'vdslprotocol' => (
  isa => 'Int', 
  is => 'ro', 
  writer => '_set_vdslprotocol'
);

=head2 hlog_near (ro)

hlog data for the near end (dlsam)

This attribute depends on the interface type. 

For ADSL it will contain an array of values between -32767 and 32768, with -32767 being
special, meaning "no measurement". 

For VDSL the "no measurement" value is 1023.

Values for all interface types are dB.

=cut
has 'hlog_near' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_hlog_near'
);

=head2 hlog_near_grpsize

In ADSL the group size (how many carriers are average over pr hlog value) is always
one. In VDSL this is set by the dslam firmware.

=cut
has 'hlog_near_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_hlog_near_grpsize'
);

=head2 hlog_far (ro)

hlog data for the far end (cpe)

This attribute depends on the interface type. 

For ADSL it will contain an array of values between -32767 and 32768, with -32767 being
special, meaning "no measurement". 

For VDSL the "no measurement" value is 1023.

Values for all interface types are dB.

=cut
has 'hlog_far' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_hlog_far'
);

=head2 hlog_far_grpsize

In ADSL the group size (how many carriers are average over pr hlog value) is always
one. In VDSL this is set by the dslam firmware.

=cut
has 'hlog_far_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_hlog_far_grpsize'
);

=head2 qln_near (ro)

qln data for the near end (dlsam)

This attribute depends on the interface type. 

For ADSL it will contain an array of values between -32767 and 32768, with -32767 being
special, meaning "no measurement". 

For VDSL the "no measurement" value is 255.

Values for all interface types are dB.

=cut
has 'qln_near' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_qln_near'
);

=head2 qln_near_grpsize

In ADSL the group size (how many carriers are average over pr qln value) is always
one. In VDSL this is set by the dslam firmware.

=cut
has 'qln_near_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_qln_near_grpsize'
);

=head2 qln_far (ro)

qln data for the far end (cpe)

This attribute depends on the interface type. 

For ADSL it will contain an array of values between -32767 and 32768, with -32767 being
special, meaning "no measurement". 

For VDSL the "no measurement" value is 255.

Values for all interface types are dB.

=cut
has 'qln_far' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_qln_far'
);

=head2 qln_far_grpsize

In ADSL the group size (how many carriers are average over pr qln value) is always
one. In VDSL this is set by the dslam firmware.

=cut
has 'qln_far_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_qln_far_grpsize'
);

=head2 snr_near (ro)

snr data for the near end (dlsam)

This attribute depends on the interface type. 

For ADSL it will contain nothing.

For VDSL the "no measurement" value is 255.

Values for all interface types are dB.

=cut
has 'snr_near' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_snr_near'
);

=head2 snr_near_grpsize

The number of carriers grouped together for each snr value.

=cut
has 'snr_near_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_snr_near_grpsize'
);

=head2 snr_far (ro)

snr data for the far end (cpe)

This attribute depends on the interface type. 

For ADSL it will contain nothing.

For VDSL the "no measurement" value is 255.

Values for all interface types are dB.

=cut
has 'snr_far' => (
  traits => ['Array'], 
  isa => 'ArrayRef[Num]',
  is => 'ro', 
  writer => '_set_snr_far'
);

=head2 snr_far_grpsize

The number of carriers grouped together for each snr value.

=cut
has 'snr_far_grpsize' => (
  isa => 'Int',
  is => 'ro', 
	default => sub { 1 }, 
  writer => '_set_snr_far_grpsize'
);

=head2 seltStatus

Contains the status of a SELT operation on the port.

=cut
has 'seltStatus' => (
  isa => 'Str',
  is => 'ro',
  default => sub { 'NA' },
  writer => '_set_seltStatus'
);

=head2 seltCableType
 
Contains the cable type reported by the IES as a result of a SELT operation.
 
 1 => 'awg24'
 2 => 'awg26'
 
=cut
has 'seltCableType' => (
  isa => 'Int',
  is => 'ro',
  default => sub { 0 },
  writer => '_set_seltCableType'
);

=head2 seltLoopEstimateLengthFt
 
 Contains the IES estimate of the loop length in Feet.
 
=cut
has 'seltLoopEstimateLengthFt' => (
  isa => 'Int',
  is => 'ro',
  default => sub { 0 },
  writer => '_set_seltLoopEstimateLengthFt'
);

=head2 seltLoopEstimateLengthMeter
 
 Contains the IES estimate of the loop length in Meters.
 
=cut
has 'seltLoopEstimateLengthMeter' => (
  isa => 'Int',
  is => 'ro',
  default => sub { 0 },
  writer => '_set_seltLoopEstimateLengthMeter'
);

=head2 dhcpDiscovery
 
Contains the number of dhcp discoveries on the port.
 
=cut
has 'dhcpDiscovery' => (
  isa => 'Int',
  is => 'ro',
  default => sub { -1 },
  writer => '_set_dhcpDiscovery'
);

=head2 dhcpOffer
 
Contains the number of dhcp offer on the port.
 
=cut
has 'dhcpOffer' => (
  isa => 'Int',
  is => 'ro',
  default => sub { -1 },
  writer => '_set_dhcpOffer'
);

=head2 dhcpRequest
 
 Contains the number of dhcp request on the port.
 
=cut
has 'dhcpRequest' => (
  isa => 'Int',
  is => 'ro',
  default => sub { -1 },
  writer => '_set_dhcpRequest'
);

=head2 dhcpAck
 
 Contains the number of dhcp ack on the port.
 
=cut
has 'dhcpAck' => (
  isa => 'Int',
  is => 'ro',
  default => sub { -1 },
  writer => '_set_dhcpAck'
);

=head2 dhcpAckBySnoopFull
 
 Contains the number of dhcp ack on the port.
 
=cut
has 'dhcpAckBySnoopFull' => (
  isa => 'Int',
  is => 'ro',
  default => sub { -1 },
  writer => '_set_dhcpAckBySnoopFull'
);

=head1 METHODS

=head2 BUILD
 
 When the object is created, we need to create an instance of the oid translater.
 
=cut
our $oid_tr;
sub BUILD {
  $oid_tr = Device::ZyXEL::IES::OID->new;
}

=head2 write_oid

Used (mainly internally) to write a new value into the specified OID on the IES.

Params:
  $oidname: Symbolic name of the OID, translated through mib files or statically through OID.pm
  $type: An SNMP type, i.e. OCTET_STRING, INTEGER aso, imported by Net::SNMP asn1
  $value: <the value to set>
  $actual: 1 => the oid indcated by oidname, and translated to an actual oid is the actual final one
           0 => Append port ID to the oid before setting

Returns:
  a status string indicating the result.
 
=cut
sub write_oid {
  my ($self, $oidname, $type, $value, $actual) = @_;
  $actual = 0 unless defined $actual;

  return "[ERROR] No set community" unless defined $self->slot->ies->set_community();

  my $oid = $oid_tr->translate( $oidname );
  
  return "[ERROR] Cant translate oidname: $oidname" unless defined( $oid );

  my ($s, $e) = Net::SNMP->session(
    -hostname  => $self->slot->ies->hostname, 
    -version   => 1,  
    -community => $self->slot->ies->set_community() 
  );

  return "[ERROR] SNMP session creation failure: $e" unless defined( $s );
  my $actualoid;
  if ( $actual == 0 ) { # $actual indicates whether or not the passed oid is the final one
    $actualoid = $oid.'.'.$self->id;
    if ( $oid =~ /%d/ ) {
      $actualoid = sprintf( $oid, $self->id );
    }
  }
  else {
    $actualoid = $oid;
  }

  my $r = $s->set_request(
    varbindlist => [ $actualoid, $type, $value] 
  );

  return "[ERROR] SNMP set error: " . $s->error() unless defined( $r );
  return 'OK';
}

=head2 read_oid

Uses Net::SNMP::Util to read the value of an oid
for a specific slot. 

=cut
sub read_oid {
  my ($self, $oidname,$postfix,$translate) = @_;

  return "ERROR, invalid oid" unless defined( $oidname );

  my $oid = $oid_tr->translate( $oidname, $postfix );
  
  return "ERROR: cant translate $oidname" unless defined($oid);
  
  my $actualoid = $oid.'.'.$self->id;
  if ( $oid =~ /%d/ ) {
    $actualoid = sprintf( $oid, $self->id );	  
  }

  return $self->slot->ies->read_oid( $actualoid, $translate );
}


=head2 read_operstatus

Asks the IES for OperStatus on the port.

=cut
sub read_operstatus {
	my $self = shift;

	my $operstatus = $self->read_oid( 'IF-MIB::ifOperStatus' );
	if ( $operstatus =~ /^[21]$/ ) {
		$self->_set_operstatus($operstatus);
	}
	return $operstatus;
}

=head2 read_uptime

Asks the IES for uptime on the port.

=cut
sub read_uptime {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $uptime = '';

  if ( $ifType eq 'ADSL' ) {
    $uptime = $self->read_oid( 'ZYXEL-IES5000-MIB::adslLineStatusUpTime' );
  }
  else {
    if ( $self->slot->ies->uptime() ne 'unknown' ) {
      # use ifLastChange in combination with IES uptime to calculate
      # the port uptime
      if ( $self->ifLastChange eq 'default' ) {
        $self->read_ifLastChange();
      }
      if ( $self->slot->ies->uptime() eq 'default' ) {
        $self->slot->ies->read_uptime();
      }
      $uptime = ticks_to_time( $self->slot->ies->uptime() - $self->ifLastChange() );
    }
  }

  $self->_set_uptime( $uptime ) if $uptime !~ /ERROR/;
  return $uptime;
}

=head2 read_profile

Asks the IES for profile on the port.

=cut
sub read_profile {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $oid = '';
  my $profile = '';

  if ( $ifType eq 'ADSL' ) {
    $oid = 'ADSL-LINE-MIB::adslLineConfProfile';
  }
  elsif ( $ifType eq 'VDSL' ) {
    $oid = 'VDSL-LINE-MIB::vdslLineConfProfile';
  }
  elsif ( $ifType eq 'SHDSL' ) {
    $oid = 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslSpanConfProfile';
  }
  
  if ( $oid ne '' ) {
	  $profile = $self->read_oid( $oid );
	  $self->profile( $profile ) unless $profile =~ /ERROR/;
  }
  return $profile;
}

=head2 write_profile
=cut
sub write_profile {
  my ($self, $new_value) = @_;
  my $ifType = $self->readIfType;
  
	my $oid;
  if ( $ifType eq 'ADSL' ) {
    $oid = 'ADSL-LINE-MIB::adslLineConfProfile';
  }
  elsif ( $ifType eq 'VDSL' ) {
    $oid = 'VDSL-LINE-MIB::vdslLineConfProfile';
  }
  elsif ( $ifType eq 'SHDSL' ) {
    $oid = 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslSpanConfProfile';
  }
  my $res = $self->write_oid( $oid, OCTET_STRING, $new_value );
  $self->profile( $new_value ) if $res eq 'OK';
  return $res;
}

=head2 read_ifInOctets

Asks the IES for ifInOctets on the port.

=cut
sub read_ifInOctets {
	my $self = shift;

	my $octets = $self->read_oid( 'IF-MIB::ifHCInOctets' );
	if ( $octets =~ /^\d+$/ ) {
		$self->_set_ifInOctets($octets);
	}
	return $octets;
}

=head2 read_ifOutOctets

Asks the IES for ifOutOctets on the port.

=cut
sub read_ifOutOctets {
	my $self = shift;

	my $octets = $self->read_oid( 'IF-MIB::ifHCOutOctets' );
	if ( $octets =~ /^\d+$/ ) {
		$self->_set_ifOutOctets($octets);
	}
	return $octets;
}

=head2 read_ifLastChange

Asks the IES for ifLastChange on the port.

=cut
sub read_ifLastChange {
	my $self = shift;

	my $lastchange = $self->read_oid( 'IF-MIB::ifLastChange' );
	if ( $lastchange =~ /^\d+$/ ) {
		$self->_set_ifLastChange($lastchange);
	}
	return $lastchange;
}

=head2 read_maxmac

Asks the IES for maxmac on the port.

=cut
sub read_maxmac {
	my $self = shift;

	my $maxmac = $self->read_oid( 'ZYXEL-IES5000-MIB::macFilterPortMacCount' );
	if ( $maxmac =~ /^\d+$/ ) {
		$self->maxmac($maxmac);
	}
	return $maxmac;
}

=head2 write_maxmac

Sets the macFilterPortMacCount value in the dslam, and the value of the attribute 
here.
 
=cut
sub write_maxmac {
  my ($self, $new_value, $old_value) = @_;
  my $res = $self->write_oid( 'ZYXEL-IES5000-MIB::macFilterPortMacCount', INTEGER, $new_value );
  if ( $res eq 'OK' ) {
    $self->maxmac( $new_value );
  }
  return $res;
}

=head2 read_adminstatus

Asks the IES for OperStatus on the port.

=cut
sub read_adminstatus {
	my $self = shift;

	my $adminstatus = $self->read_oid( 'IF-MIB::ifAdminStatus' );
	if ( $adminstatus =~ /^[21]$/ ) {
		$self->adminstatus($adminstatus);
	}
	return $adminstatus;
}

=head2 write_adminstatus

 Sets ifAdminStatus on the Port on the device.
 
=cut
sub write_adminstatus {
  my ($self, $new_value) = @_;
  my $res = $self->write_oid( 'IF-MIB::ifAdminStatus', INTEGER, $new_value );
  if ( $res eq 'OK' ) {
    $self->adminstatus($new_value);
  }
  return $res;
}

=head2 read_userinfo

Asks the IES for userinfo on the port.

=cut
sub read_userinfo {
	my $self = shift;

	my $userinfo = $self->read_oid( 'ZYXEL-IES5000-MIB::subrPortName' );
	if ( $userinfo !~ /ERROR/ ) {
		$self->_set_userinfo($userinfo);
	}
	return $userinfo;
}

=head2 readIfType

Retrieves the ifType [ADSL, VDSL, SHDSL] from the associated
slot object. If cardtype (which determines the ifType) is not
previosly read from the dslam, and present in the object, it start
by reading the cardtype from the IES.

=cut
sub readIfType {
	my $self = shift;
	if ( defined $self->slot->cardtype && $self->slot->cardtype ne '' ) {
		# trust ifType
		return $self->slot->iftype;
  }
	else {
		$self->slot->read_cardtype();
		return $self->slot->iftype;
	}
}

=head2 read_maxdown

Asks the IES for max attainable downstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_maxdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $maxdown = '';

	if ( $ifType eq 'ADSL' ) {
	  $maxdown = $self->read_oid( 'ADSL-LINE-MIB::adslAtucCurrAttainableRate' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $maxdown = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrAttainableRate', '%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $maxdown = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate' );
	}
	$self->_set_maxdown($maxdown) if $maxdown =~ /^\d+$/;
	return $maxdown;
}

=head2 read_maxup

Asks the IES for maximum attainable speed upstream on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_maxup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $maxup = '';

	if ( $ifType eq 'ADSL' ) {
	  $maxup = $self->read_oid( 'ADSL-LINE-MIB::adslAturCurrAttainableRate' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $maxup = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrAttainableRate', '%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $maxup = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate' );
	}
	$self->_set_maxup($maxup) if $maxup =~ /^\d+$/;
	return $maxup;
}

=head2 read_downspeed

Asks the IES for the current downstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_downspeed {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $downspeed = '';

	if ( $ifType eq 'ADSL' ) {
	  $downspeed = $self->read_oid( 'ADSL-LINE-MIB::adslAtucChanCurrTxRate' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $downspeed = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrLineRate', '%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $downspeed = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate' );
	}
	$self->_set_downspeed($downspeed) if $downspeed =~ /^\d+$/;
	return $downspeed;
}

=head2 read_upspeed

Asks the IES for current upstream speed on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_upspeed {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $upspeed = '';

	if ( $ifType eq 'ADSL' ) {
	  $upspeed = $self->read_oid( 'ADSL-LINE-MIB::adslAturChanCurrTxRate' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $upspeed = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrLineRate', '%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $upspeed = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate' );
	}
	$self->_set_upspeed($upspeed) if $upspeed =~ /^\d+$/;
	return $upspeed;
}

=head2 read_snrdown

Asks the IES for the SNR for the downstream channel on the port.

Network side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_snrdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $snrdown = '';

	if ( $ifType eq 'ADSL' ) {
	  $snrdown = $self->read_oid( 'ADSL-LINE-MIB::adslAturCurrSnrMgn' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $snrdown = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrSnrMgn', '%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $snrdown = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrSnrMgn', '%d.2.1.1' );
	}
	$self->_set_snrdown($snrdown) if $snrdown =~ /^\d+$/;
	return $snrdown;
}

=head2 read_snrup

Asks the IES for SNR Margin on the upstream channel on the port.

Customer side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_snrup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $snrup = '';

	if ( $ifType eq 'ADSL' ) {
	  $snrup = $self->read_oid( 'ADSL-LINE-MIB::adslAtucCurrSnrMgn' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $snrup = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrSnrMgn', '%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $snrup = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrSnrMgn', '%d.1.2.1' );
	}
	$self->_set_snrup($snrup) if $snrup =~ /^\d+$/;
	return $snrup;
}

=head2 read_atndown

Asks the IES for the Attenaution for the downstream channel on the port.

Network side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_atndown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $atndown = '';

	if ( $ifType eq 'ADSL' ) {
	  $atndown = $self->read_oid( 'ADSL-LINE-MIB::adslAturCurrAtn' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $atndown = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrAtn', '%d.1' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $atndown = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrAtn', '%d.2.1.1' );
	}
	$self->_set_atndown($atndown) if $atndown =~ /^\d+$/;
	return $atndown;
}

=head2 read_atnup

Asks the IES for Attenaution on the upstream channel on the port.

Customer side in case of SHDSL.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_atnup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $atnup = '';

	if ( $ifType eq 'ADSL' ) {
	  $atnup = $self->read_oid( 'ADSL-LINE-MIB::adslAtucCurrAtn' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $atnup = $self->read_oid( 'VDSL-LINE-MIB::vdslPhysCurrAtn', '%d.2' );
	}
	elsif ( $ifType eq 'SHDSL' ) {
	  $atnup = $self->read_oid( 'HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrAtn', '%d.1.2.1' );
	}
	$self->_set_atnup($atnup) if $atnup =~ /^\d+$/;
	return $atnup;
}

=head2 read_inpdown

Asks the IES for the Impulse Noice Protection level for the downstream channel on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_inpdown {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $inpdown = 0;

	if ( $ifType eq 'ADSL' ) {
	  $inpdown = $self->read_oid( 'ZYXEL-IES5000-MIB::adslLineConfAtucInp' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $inpdown = $self->read_oid( 'ZYXEL-IES5000-MIB::vdslLineConfVturInp' );
	}
	$self->inp_down($inpdown) if $inpdown =~ /^\d+$/;;
	return $inpdown;
}

=head2 write_inpdown

Set the INP value in the device, and sets the attribute upon succes.
 
=cut
sub write_inpdown {
  my ($self, $new_value) = @_;
  my $ifType = $self->readIfType;
  my $res = 'unknown';
  
  if ( $ifType eq 'ADSL' ) {
	  # The INP value in ADSL must be [1..7] each unit
	  #     zero(1),
	  #     zero_point_five(2),
	  #     one(3),
	  #     two(4),
	  #     four(5),
	  #     eight(6),
	  #     sixteen(7)
	  if ( $new_value > 0 && $new_value < 8 ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::adslLineConfAtucInp', INTEGER, $new_value );
	  }
  }
  elsif ( $ifType eq 'VDSL' ) {
    # The INP value in VDSL must by [1..160] as is a .1 precision float
	  if ( $new_value > 0 && $new_value <= 160 ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::vdslLineConfVturInp', INTEGER, $new_value );
	  }
  }
  $self->inp_down( $new_value ) if $res eq 'OK';
  return $res;
}

=head2 read_inpup

Asks the IES for the Impulse Noice Protection level for the upstream channel on the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_inpup {
	my $self = shift;
 
	my $ifType = $self->readIfType;
	my $inpup = 0;

	if ( $ifType eq 'ADSL' ) {
	  $inpup = $self->read_oid( 'ZYXEL-IES5000-MIB::adslLineConfAturInp' );
	}
	elsif ( $ifType eq 'VDSL' ) {
	  $inpup = $self->read_oid( 'ZYXEL-IES5000-MIB::vdslLineConfVtucInp' );
	}
	$self->inp_up($inpup) if $inpup =~ /^\d+$/;
	return $inpup;
}

=head2 write_inpup
=cut
sub write_inpup {
  my ($self, $new_value) = @_;
  my $ifType = $self->readIfType;
  my $res = 'unknown';
  
  if ( $ifType eq 'ADSL' ) {
	  # The INP value in ADSL must be [1..7] each unit
	  #     zero(1),
	  #     zero_point_five(2),
	  #     one(3),
	  #     two(4),
	  #     four(5),
	  #     eight(6),
	  #     sixteen(7)
	  if ( $new_value > 0 && $new_value < 8 ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::adslLineConfAturInp', INTEGER, $new_value );
	  }
  }
  elsif ( $ifType eq 'VDSL' ) {
    # The INP value in VDSL must by [1..160] as is a .1 precision float
	  if ( $new_value > 0 && $new_value <= 160 ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::vdslLineConfVtucInp', INTEGER, $new_value );
	  }
  }
  $self->inp_up( $new_value ) if $res eq 'OK';
  return $res;
}

=head2 read_annexM

Asks the IES for the Annex M setting for the ADSL port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_annexM {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $annexM = 0;

  if ( $ifType eq 'ADSL' ) {
    $annexM = $self->read_oid( 'ZYXEL-IES5000-MIB::adslLineConfAnnexM' );
  }
  $self->annexM($annexM) if $annexM =~ /^\d+$/;
  return $annexM;
}

=head2 write_annexM
 
Sets the annexM value on the port on the IES.
 
=cut
sub write_annexM {
  my ($self, $new_value, $old_value) = @_;
  my $ifType = $self->readIfType;
  my $res = 'unknown';
  
  if ( $ifType eq 'ADSL' ) {
	  if ( $new_value =~ /^[12]$/ ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::adslLineConfAnnexM', INTEGER, $new_value );
	  }
  }
  $self->annexM( $new_value ) if $res eq 'OK';
  return $res;
}

=head2 read_annexL

Asks the IES for the Annex L setting for the ADSL port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_annexL {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $annexL = 0;

  if ( $ifType eq 'ADSL' ) {
    $annexL = $self->read_oid( 'ZYXEL-IES5000-MIB::adslLineConfAnnexL' );
  }
  $self->annexL($annexL) if $annexL =~ /^\d+$/;
  return $annexL;
}

=head2 write_annexL
 
Sets the annexL value on the port on the IES.

=cut
sub write_annexL {
  my ($self, $new_value, $old_value) = @_;
  my $ifType = $self->readIfType;
  my $res = 'unknown';
  
  if ( $ifType eq 'ADSL' ) {
	  if ( $new_value =~ /^[123]$/ ) {
      $res = $self->write_oid( 'ZYXEL-IES5000-MIB::adslLineConfAnnexL', INTEGER, $new_value );
	  }
  }
  $self->annexL( $new_value ) if $res eq 'OK';
  return $res;
}

=head2 read_wirepairmode

Asks the IES for the S.HDSL Wirepair mode of the port.

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_wirepairmode {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $wpm = 0;

  if ( $ifType eq 'SHDSL' ) {
    $wpm = $self->read_oid( 'ZYXEL-IES5000-MIB::shdslLineStatusWirePair' );
  }
  $self->_set_wirepairmode($wpm) if $wpm =~ /^\d+$/;
  return $wpm;
}

=head2 read_vdslprotocol

Asks the IES for the actual VDSL protocol used on the port

Different OID's for different slot types, determined
by the slot cardtype.

=cut
sub read_vdslprotocol {
  my $self = shift;

  my $ifType = $self->readIfType;
  my $protocol = 0;

  if ( $ifType eq 'VDSL' ) {
    $protocol = $self->read_oid( 'ZYXEL-IES5000-MIB::vdslLineStatsProtocol' );
  }
  $self->_set_vdslprotocol($protocol) if $protocol =~ /^\d+$/;
  return $protocol;
}

=head2 read_hlog_near

Asks the dslam for the near end part (dslam side) of the hlog data.

Finds the correct oids to ask for, depending on the ifType
=cut
sub read_hlog_near {
  my $self = shift;

  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # hlog near for VDSL = hlog down
	  my $hlog_down = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturHlog', '', {'-octetstring' => 0x0});
	  if ( $hlog_down !~ /^ERROR/ ) {
	    my $hlog_down_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturHlogGroupSize');
      my @words = unpack("(n2)*", $hlog_down);
	    # 1023 special => no measurement
      # Hlog(f) value is represented as (6-m(i)/10),  with m(i) in the range 0 to 1022.
      foreach my $w ( @words ) {
        if ( $w != 1023 ) {
          $w = 6 - $w/10;
        }
        push @swords, $w;
      }
      if ( $hlog_down_grpsize =~ /^\d+$/ ) {
        $self->_set_hlog_near_grpsize( $hlog_down_grpsize );
			}
	  }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my $hlog_dslam = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAturHlog', '', {'-octetstring' => 0x0});
    if ( $hlog_dslam !~ /^ERROR/ ) {
      # 16 bit values. tenths of db
      my @words = unpack("(n)*", $hlog_dslam);
      foreach my $w ( @words ) {
        my $signed = to_signed16int( $w );
        $signed /= 10 unless $signed == -32768;
        push @swords, $signed;
      }
    }
    $self->_set_hlog_near_grpsize( 1 );
  }
  $self->_set_hlog_near(\@swords);
  return $self->hlog_near;
}

=head2 read_hlog_far

Asks the dslam for the far end part (cpe side) of the hlog data.

Finds the correct oids to ask for, depending on the ifType
=cut
sub read_hlog_far {
  my $self = shift;
  
  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # hlog far for VDSL = hlog up
	  my $hlog_up = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucHlog', '', {'-octetstring' => 0x0});
	  if ( $hlog_up !~ /^ERROR/ ) {
	    my $hlog_up_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucHlogGroupSize');
      my @words = unpack("(n2)*", $hlog_up);
	    # 1023 special => no measurement
      # Hlog(f) value is represented as (6-m(i)/10),  with m(i) in the range 0 to 1022.
      foreach my $w ( @words ) {
        if ( $w != 1023 ) {
          $w = 6 - $w/10;
        }
        push @swords, $w;
      }
      if ( $hlog_up_grpsize =~ /^\d+$/ ) {
        $self->_set_hlog_far_grpsize( $hlog_up_grpsize );
			}
	  }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my $hlog_cpe_first = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAtucHlog1', '', {'-octetstring' => 0x0});
    if ( $hlog_cpe_first !~ /^ERROR/ ) {
      my $hlog_cpe_second = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAtucHlog2', '', {'-octetstring' => 0x0});
      if ( $hlog_cpe_second !~ /^ERROR/ ) {
        # 16 bit values. tenths of db
        my @words = unpack("(n)*", $hlog_cpe_first.$hlog_cpe_second);
        foreach my $w ( @words ) {
          my $signed = to_signed16int( $w );
          $signed /= 10 unless $signed == -32768;
          push @swords, $signed;
        }
      }
    }
    $self->_set_hlog_far_grpsize( 1 );
  }
    
  $self->_set_hlog_far(\@swords);
  return $self->hlog_far;
}

=head2 read_qln_near

Asks the dslam for the near end part (dslam side) of the qln data.

Finds the correct oids to ask for, depending on the ifType
=cut
sub read_qln_near {
  my $self = shift;

  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # qln near for VDSL = qln down
	  my $qln_down = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturQln', '', {'-octetstring' => 0x0});
	  if ( $qln_down !~ /^ERROR/ ) {
	    my $qln_down_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturQlnGroupSize');
      my @bytes = unpack("(C)*", $qln_down);
      # 255 special => no measurement
      # The QLN(f) is represented as ( -23-n(i)/2),  with n(i) in the range 0 to 254.
      foreach my $b ( @bytes ) {
        if ( $b != 255 ) {
          $b = - 23 - $b/2;
        }
        push @swords, $b;
      }
      if ( $qln_down_grpsize =~ /^\d+$/ ) {
        $self->_set_qln_near_grpsize( $qln_down_grpsize );
			}
	  }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my $qln_dslam = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAturQln', '', {'-octetstring' => 0x0});
    if ( $qln_dslam !~ /^ERROR/ ) {
      # 16 bit values. tenths of db
      my @words = unpack("(n)*", $qln_dslam);
      foreach my $w ( @words ) {
        my $signed = to_signed16int( $w );
        $signed /= 10 unless $signed == -32768;
        push @swords, $signed;
      }
    }
    $self->_set_qln_near_grpsize( 1 );
  }
  $self->_set_qln_near(\@swords);
  return $self->qln_near;
}

=head2 read_qln_far

Asks the dslam for the far end part (cpe side) of the qln data.

Finds the correct oids to ask for, depending on the ifType
=cut
sub read_qln_far {
  my $self = shift;

  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # qln far for VDSL = qln up
	  my $qln_up = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucQln', '', {'-octetstring' => 0x0});
	  if ( $qln_up !~ /^ERROR/ ) {
	    my $qln_up_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucQlnGroupSize');
      my @bytes = unpack("(C)*", $qln_up);
	    # 255 special => no measurement
      # The QLN(f) is represented as ( -23-n(i)/2),  with n(i) in the range 0 to 254.
      foreach my $b ( @bytes ) {
        if ( $b != 255 ) {
          $b = - 23 - $b/2;
        }
        push @swords, $b;
      }
      if ( $qln_up_grpsize =~ /^\d+$/ ) {
        $self->_set_qln_far_grpsize( $qln_up_grpsize );
			}
	  }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my $qln_cpe_first = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAtucQln1', '', {'-octetstring' => 0x0});
    if ( $qln_cpe_first !~ /^ERROR/ ) {
      my $qln_cpe_second = $self->read_oid('ZYXEL-IES5000-MIB::adslLineStatsAtucQln2', '', {'-octetstring' => 0x0});
      if ( $qln_cpe_second !~ /^ERROR/ ) {
        # 16 bit values. tenths of db
        my @words = unpack("(n)*", $qln_cpe_first.$qln_cpe_second);
        foreach my $w ( @words ) {
          my $signed = to_signed16int( $w );
          $signed /= 10 unless $signed == -32768;
          push @swords, $signed;
        }
      }
    }
    $self->_set_qln_far_grpsize( 1 );
  }
  $self->_set_qln_far(\@swords);
  return $self->qln_far;
}

=head2 read_snr_near

Asks the dslam for the downstream part of the snr data.

=cut
sub read_snr_near {
  my $self = shift;

  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # snr near for VDSL = snr down
	  my $snr_down = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturSnr', '', {'-octetstring' => 0x0});
	  if ( $snr_down !~ /^ERROR/ ) {
	    my $snr_down_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVturSnrGroupSize');
      my @bytes = unpack("(C)*", $snr_down);
      # 255 special => no measurement
      # Octet i is set to a value in the range 0 to 254 (-32 + vdslLineStatsVtucSnr (i)/2) in dB
      foreach my $b ( @bytes ) {
        if ( $b != 255 ) {
          $b = - 32 + $b/2;
        }
        push @swords, $b;
      }
      if ( $snr_down_grpsize =~ /^\d+$/ ) {
        $self->_set_snr_near_grpsize( $snr_down_grpsize );
			}
	  }
  }
  $self->_set_snr_near(\@swords);
  return $self->snr_near;
}

=head2 read_snr_far

Asks the dslam for the upstream part of the snr data.

=cut

sub read_snr_far {
  my $self = shift;

  my @swords = ();
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
	  # snr far for VDSL = snr up
	  my $snr_up = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucSnr', '', {'-octetstring' => 0x0});
	  if ( $snr_up !~ /^ERROR/ ) {
	    my $snr_up_grpsize = $self->read_oid('ZYXEL-IES5000-MIB::vdslLineStatsVtucSnrGroupSize');
      my @bytes = unpack("(C)*", $snr_up);
	    # 255 special => no measurement
      # Octet i is set to a value in the range 0 to 254 (-32 + vdslLineStatsVturSnr (i)/2) in dB
      foreach my $b ( @bytes ) {
        if ( $b != 255 ) {
          $b = - 32 + $b/2;
        }
        push @swords, $b;
      }
      if ( $snr_up_grpsize =~ /^\d+$/ ) {
        $self->_set_snr_far_grpsize( $snr_up_grpsize );
			}
	  }
  }
  $self->_set_snr_far(\@swords);
  return $self->snr_far;
}

=head2 write_selt_begin

Sets the SeltOps thus initiating the SELT procedure on the port.

=cut
sub write_selt_begin {
  my $self = shift;
  
  my $res = 'ERROR: nothing done';
  # Set the target port
  $res = $self->write_oid( 'ZYXEL-IES5000-MIB::seltTarget.0', INTEGER, $self->id, 1);
  if ( $res eq 'OK' ) {
    # Tell the DSLAM to start the test.
    $res = $self->write_oid( 'ZYXEL-IES5000-MIB::seltOps.0', INTEGER, 1, 1);
  }
  return $res;
}

=head2 read_selt_results
 
Attempts to fetch the results of a SELT operation on the port.

Stores fetched values in the corresponding port attributes.
 
=cut
sub read_selt_results {
  my $self = shift;
  
  my $oidlist = {};
  foreach my $oidname ( qw/seltStatus seltCableType seltLoopEstimateLengthFt seltLoopEstimateLengthMeter/ ) {
    $oidlist->{$oidname} = $oid_tr->translate( sprintf("ZYXEL-IES5000-MIB::%s.0",$oidname) );
  }
  my $res = $self->slot->ies->read_oids( $oidlist );
  return $res unless ref( $res ) eq 'HASH';
  
  foreach my $k ( keys %{$res} ) {
    my $setter = "_set_$k";
    $self->$setter($res->{$k});
  }
  return $res;
}

=head2 read_dhcp_stats
 
Fetches the number of DHCPDISCOVER,-OFFER,-REQUEST and -ACK from the IES DHCP relay feature.

Params:
  None
 
Returns:
 Hash containing values for DISCOVER,OFFER,REQUEST,ACK and ACKBYSNOOPFULL

=cut
sub read_dhcp_stats {
  my $self = shift;
  
  my $oidlist = {};
  foreach my $oidname ( qw/dhcpDiscovery dhcpOffer dhcpRequest dhcpAck dhcpAckBySnoopFull/ ) {
    $oidlist->{$oidname} = $oid_tr->translate( sprintf("ZYXEL-IES5000-MIB::%s",$oidname) ) .'.'.$self->id;
  }
  my $res = $self->slot->ies->read_oids( $oidlist );
  return $res unless ref( $res ) eq 'HASH';
  
  foreach my $k ( keys %{$res} ) {
    my $setter = "_set_$k";
    $self->$setter($res->{$k});
  }
  return $res;
 
}

=head2 read_snoop_iplist
 
 Retrieves the list of IP-Mac combination in the snoop table
 for a given port.
 
=cut
sub read_snoop_iplist {
  my $self = shift;
  my $res = {};
  
  my $oidbase = $oid_tr->translate('ZYXEL-IES5000-MIB::dhcpSnoopMac');
  my $oid = $oidbase.'.'.$self->id;
  
  my $rawres = $self->slot->ies->walk_oid( $oid, { -octetstring => 0x0 } );
  return $rawres if ( ref($rawres) eq 'SCALAR' && $rawres =~ /^ERROR/);
  foreach my $ip ( keys %{$rawres} ) {
    $ip =~ /^\d+\.\d+\.\d+.\d+$/ or next;
    $res->{$ip} = unpack('H*',$rawres->{$ip});
    if ( $res->{$ip} =~ /^(..)(..)(..)(..)(..)(..)$/ ) {
      $res->{$ip} = sprintf("%s:%s:%s:%s:%s:%s",$1,$2,$3,$4,$5,$6);
    }
  }
  return $res;
}

=head2 read_es_interval

 Reads the ES Interval MIB, which returns a value for each 15 minute interval during the past 24 hours.
 
=cut
sub read_es_interval {
  my $self = shift;
  my $res = {};
  
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
    my $oidbase = $oid_tr->translate('VDSL-LINE-MIB::vdslPerfIntervalESs');
    my $oid = $oidbase.'.'.$self->id;
    
    my $rawres = $self->slot->ies->walk_oid( $oid );
    return $rawres if ( ref($rawres) eq 'SCALAR' && $rawres =~ /^ERROR/);
    foreach my $interval ( keys %{$rawres} ) {
      $interval =~ /^([12])\.(\d+)$/ or next;
      my ($dir,$i) = ($1,$2);
      $dir = $dir == 1 ? 'near' : 'far';
      $res->{$dir}{$i} = $rawres->{$interval};
    }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my %names = ( 'near' => 'ADSL-LINE-MIB::adslAtucIntervalESs', 'far' => 'ADSL-LINE-MIB::adslAturIntervalESs' );
    foreach my $dir ( keys %names ) {
      my $oidbase = $oid_tr->translate($names{$dir});
      my $oid = $oidbase.'.'.$self->id;

      my $rawres = $self->slot->ies->walk_oid( $oid );
      return $rawres if ( ref($rawres) eq 'SCALAR' && $rawres =~ /^ERROR/);
      foreach my $interval ( keys %{$rawres} ) {
        $interval =~ /^\d+$/ or next;
        $res->{$dir}{$interval} = $rawres->{$interval};
      }
    }
  }
  else {
    return "ERROR: Not supported";
  }
  return $res;
}

=head2 read_crc_interval
 
 Reads the ES Interval MIB, which returns a value for each 15 minute interval during the past 24 hours.
 
=cut
sub read_crc_interval {
  my $self = shift;
  my $res = {};
  
  my $ifType = $self->readIfType;
  if ( $ifType eq 'VDSL' ) {
    my $oidbase = $oid_tr->translate('VDSL-LINE-MIB::vdslChanIntervalBadBlks');
    my $oid = $oidbase.'.'.$self->id;
    
    my $rawres = $self->slot->ies->walk_oid( $oid );
    return $rawres if ( ref($rawres) eq 'SCALAR' && $rawres =~ /^ERROR/);
    foreach my $interval ( keys %{$rawres} ) {
      $interval =~ /^([12])\.(\d+)$/ or next;
      my ($dir,$i) = ($1,$2);
      $dir = $dir == 1 ? 'near' : 'far';
      $res->{$dir}{$i} = $rawres->{$interval};
    }
  }
  elsif ( $ifType eq 'ADSL' ) {
    my %names = ( 'near' => 'ADSL-LINE-MIB::adslAtucChanIntervalUncorrectBlks', 'far' => 'ADSL-LINE-MIB::adslAturChanIntervalUncorrectBlks' );
    foreach my $dir ( keys %names ) {
      my $oidbase = $oid_tr->translate($names{$dir});
      my $oid = $oidbase.'.'.$self->id;
      
      my $rawres = $self->slot->ies->walk_oid( $oid );
      return $rawres if ( ref($rawres) eq 'SCALAR' && $rawres =~ /^ERROR/);
      foreach my $interval ( keys %{$rawres} ) {
        $interval =~ /^\d+$/ or next;
        $res->{$dir}{$interval} = $rawres->{$interval};
      }
    }
  }
  else {
    return "ERROR: Not supported";
  }
  return $res;
}


=head2 fetchAllDetails

Retrieves the details of a port from the IES.

Fetches all relevant information from the port, and fills values into the appropriate attributes.

=cut

sub fetchAllDetails {
  my $self = shift;
  my $meta = $self->meta();

  foreach my $method ( $meta->get_method_list ) {
    if ( $method =~ /^read_/ && $method ne 'read_oid' ) {
      my $res = $self->$method;
      return $res if $res =~ /ERROR/i;
    }
  }
  return 'OK';
}


=head2 fetchDetails
 
 Retrieves the details of a port from the IES.
 
 Fetches all relevant information from the port, and fills values into the appropriate attributes.
 
=cut

our %snmp_details = (
  'Common' => [
    ['operStatus','IF-MIB::ifOperStatus',''],
    ['adminStatus','IF-MIB::ifAdminStatus',''],
    ['ifLastChange','IF-MIB::ifLastChange',''],
    ['macFilterCount','ZYXEL-IES5000-MIB::macFilterPortMacCount',''],
    ['inOctets','IF-MIB::ifHCInOctets',''],
    ['outOctets','IF-MIB::ifHCOutOctets',''],
  ],
  'ADSL' => [
    ['profile','ADSL-LINE-MIB::adslLineConfProfile',''],
    ['maxAttainableDown','ADSL-LINE-MIB::adslAtucCurrAttainableRate',''],
    ['maxAttainableUp','ADSL-LINE-MIB::adslAturCurrAttainableRate',''],
    ['currSpeedDown','ADSL-LINE-MIB::adslAtucChanCurrTxRate',''],
    ['currSpeedUp','ADSL-LINE-MIB::adslAturChanCurrTxRate',''],
    ['snrDown','ADSL-LINE-MIB::adslAtucCurrSnrMgn',''],
    ['snrUp','ADSL-LINE-MIB::adslAturCurrSnrMgn',''],
    ['atnDown','ADSL-LINE-MIB::adslAtucCurrAtn',''],
    ['atnUp','ADSL-LINE-MIB::adslAturCurrAtn',''],
    ['lineUptime','ZYXEL-IES5000-MIB::adslLineStatusUpTime',''],
    ['inpDown','ZYXEL-IES5000-MIB::adslLineConfAtucInp',''],
    ['inpUp','ZYXEL-IES5000-MIB::adslLineConfAturInp',''],
    ['annexM','ZYXEL-IES5000-MIB::adslLineConfAnnexM',''],
    ['annexL','ZYXEL-IES5000-MIB::adslLineConfAnnexL',''],
  ],
  'VDSL' => [
    ['profile','VDSL-LINE-MIB::vdslLineConfProfile',''],
    ['maxAttainableDown','VDSL-LINE-MIB::vdslPhysCurrAttainableRate','%d.1'],
    ['maxAttainableUp','VDSL-LINE-MIB::vdslPhysCurrAttainableRate','%d.2'],
    ['currSpeedDown','VDSL-LINE-MIB::vdslPhysCurrLineRate','%d.1'],
    ['currSpeedUp','VDSL-LINE-MIB::vdslPhysCurrLineRate','%d.2'],
    ['snrDown','VDSL-LINE-MIB::vdslPhysCurrSnrMgn','%d.1'],
    ['snrUp','VDSL-LINE-MIB::vdslPhysCurrSnrMgn','%d.2'],
    ['atnDown','VDSL-LINE-MIB::vdslPhysCurrAtn','%d.1'],
    ['atnUp','VDSL-LINE-MIB::vdslPhysCurrAtn','%d.2'],
    ['protocol','ZYXEL-IES5000-MIB::vdslLineStatsProtocol',''],
    ['inpDown','ZYXEL-IES5000-MIB::vdslLineConfVturInp',''],
    ['inpUp','ZYXEL-IES5000-MIB::vdslLineConfVtucInp',''],
  ],
  'SHDSL' => [
    ['profile','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslSpanConfProfile',''],
    ['lineRate','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslStatusActualLineRate',''],
    ['snrDown','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrSnrMgn','%d.2.1.1'],
    ['snrUp','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrSnrMgn','%d.1.2.1'],
    ['atnDown','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrAtn','%d.2.1.1'],
    ['atnUp','HDSL2-SHDSL-LINE-MIB::hdsl2ShdslEndpointCurrAtn','%d.1.2.1'],
    ['wirePairMode','ZYXEL-IES5000-MIB::shdslLineStatusWirePair',''],
  ],
);

my %set_map = (
  'profile' => 'profile',
  'operStatus' => '_set_operstatus',
  'adminStatus' => 'adminstatus',
  'macFilterCount' => 'maxmac',
  'maxAttainableDown' => '_set_maxdown',
  'maxAttainableUp' => '_set_maxup',
  'currSpeedDown' => '_set_downspeed',
  'currSpeedUp' => '_set_upspeed',
  'snrDown' => '_set_snrdown',
  'snrUp' => '_set_snrup',
  'atnDown' => '_set_atndown',
  'atnUp' => '_set_atnup',
  'inpDown' => 'inp_down',
  'inpUp' => 'inp_up',
  'annexM' => 'annexM',
  'annexL' => 'annexL',
  'protocol' => '_set_vdslprotocol',
  'linerate' => ['_set_downspeed','_set_upspeed'],
  'wirePairMode' => '_set_wirepairmode',
  'inOctets' => '_set_ifInOctets',
  'outOctets' => '_set_ifOutOctets',
);

sub fetchDetails {
  my $self = shift;

  my $oidlist = {};
  my $ifType = $self->readIfType;
  my @sections = ('Common',$ifType);
  foreach my $dk ( @sections ) {
    foreach my $dl ( @{$snmp_details{$dk}} ) {
      my $oid = $oid_tr->translate( $dl->[1], $dl->[2]  );
      my $actualoid = $oid.'.'.$self->id;
      if ( $oid =~ /%d/ ) {
        $actualoid = sprintf( $oid, $self->id );
      }
      $oidlist->{$dl->[0]} = $actualoid;
    }
  }
  
  my $res = $self->slot->ies->read_oids( $oidlist );
  return $res unless ref( $res ) eq 'HASH';
  
  my $nofSet = 0;
  foreach my $key ( keys %set_map ) {
    if ( defined( $res->{$key} ) ) {
      $nofSet++;
      if ( ref( $set_map{$key} ) eq 'LIST' ) {
        foreach my $setter ( @{$set_map{$key}} ) {
          $self->$setter( $res->{$key} );
        }
      }
      else {
        my $setter = $set_map{$key};
        $self->$setter($res->{$key});
      }
    }
  }
  return $nofSet>0?'OK':'ERROR: nothing set';
}

=head1 Private Methods

=head2 to_signed16int

Method that converts a 16 bit unsigned to a signed value

=cut
sub to_signed16int {
  my ($num) = @_;
  return $num >> 15 ? $num - 2 ** 16 : $num;
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Device::ZyXEL::IES::Port


	You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Device-ZyXEL-IES>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Device-ZyXEL-IES>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Device-ZyXEL-IES>

=item * Search CPAN

L<http://search.cpan.org/dist/Device-ZyXEL-IES/>

=back


=head1 ACKNOWLEDGEMENTS

Fullrate (http://www.fullrate.dk)
  Thanks for allowing me to be introduced to the "wonderful" device ;)
	And thanks for donating some of my work time to create this module and 
	sharing it with the world.

=head1 COPYRIGHT & LICENSE

Copyright 2012 Jesper Dalberg,  all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

__PACKAGE__->meta->make_immutable;

1; # End of Device::ZyXEL::IES::Port
