=head1 NAME

Linux::Ethtool::Settings - Manipulate link-level network interface settings

=head1 SYNOPSIS

  use Linux::Ethtool::Settings;
  
  my $settings = Linux::Ethtool::Settings->new("eth0") or die($!);
  
  # Show the current/supported modes.
  
  my $current_speed  = $settings->speed();
  my $current_duplex = $settings->duplex() ? "full" : "half";
  
  print "Current speed:    $current_speed Mbps, $current_duplex duplex\n";
  
  my @supported_modes = $settings->supported_modes();
  
  print "Supported speeds: @supported_modes\n";
  
  # Force the interface to 10Mbps, half duplex
  
  $settings->autoneg(0);
  $settings->speed(10);
  $settings->duplex(0);
  
  $settings->apply() or die($!);
  
  # Turn auto-negotiation back on. Setting advertising to supported is required
  # if the object was constructed when auto-negotiation was disabled or Linux
  # will try to auto-negotiate with no speeds...
  
  $settings->autoneg(1);
  $settings->advertising($settings->supported);
  
  $settings->apply() or die($!);

=head1 DESCRIPTION

This module provides a wrapper around the C<ethtool_cmd> structure and
associated ioctls, mainly used for configuring link-level settings such as
speed/duplex and auto-negotiation.

All the constants in this module may be imported individually or by using the
C<all> import tag.

=head1 METHODS

=cut

package Linux::Ethtool::Settings;

use strict;
use warnings;

our $VERSION = "0.11";

require XSLoader;
XSLoader::load("Linux::Ethtool::Settings");

use Exporter qw(import);

our @EXPORT_OK = qw(
	SUPPORTED_10baseT_Half
	SUPPORTED_10baseT_Full
	SUPPORTED_100baseT_Half
	SUPPORTED_100baseT_Full
	SUPPORTED_1000baseT_Half
	SUPPORTED_1000baseT_Full
	SUPPORTED_Autoneg
	SUPPORTED_TP
	SUPPORTED_AUI
	SUPPORTED_MII
	SUPPORTED_FIBRE
	SUPPORTED_BNC
	SUPPORTED_10000baseT_Full
	SUPPORTED_Pause
	SUPPORTED_Asym_Pause
	SUPPORTED_2500baseX_Full
	SUPPORTED_Backplane
	SUPPORTED_1000baseKX_Full
	SUPPORTED_10000baseKX4_Full
	SUPPORTED_10000baseKR_Full
	SUPPORTED_10000baseR_FEC
	
	ADVERTISED_10baseT_Half
	ADVERTISED_10baseT_Full
	ADVERTISED_100baseT_Half
	ADVERTISED_100baseT_Full
	ADVERTISED_1000baseT_Half
	ADVERTISED_1000baseT_Full
	ADVERTISED_Autoneg
	ADVERTISED_TP
	ADVERTISED_AUI
	ADVERTISED_MII
	ADVERTISED_FIBRE
	ADVERTISED_BNC
	ADVERTISED_10000baseT_Full
	ADVERTISED_Pause
	ADVERTISED_Asym_Pause
	ADVERTISED_2500baseX_Full
	ADVERTISED_Backplane
	ADVERTISED_1000baseKX_Full
	ADVERTISED_10000baseKX4_Full
	ADVERTISED_10000baseKR_Full
	ADVERTISED_10000baseR_FEC
	
	PORT_TP
	PORT_AUI
	PORT_MII
	PORT_FIBRE
	PORT_BNC
	PORT_OTHER
	
	XCVR_INTERNAL
	XCVR_EXTERNAL
	XCVR_DUMMY1
	XCVR_DUMMY2
	XCVR_DUMMY3
);

our %EXPORT_TAGS = (
	all => [ @EXPORT_OK ],
);

use Linux::Ethtool::Constants;

# Duplicate the constants here so we can export them.

use constant {
	SUPPORTED_10baseT_Half       => Linux::Ethtool::Constants::SUPPORTED_10baseT_Half,
	SUPPORTED_10baseT_Full       => Linux::Ethtool::Constants::SUPPORTED_10baseT_Full,
	SUPPORTED_100baseT_Half      => Linux::Ethtool::Constants::SUPPORTED_100baseT_Half,
	SUPPORTED_100baseT_Full      => Linux::Ethtool::Constants::SUPPORTED_100baseT_Full,
	SUPPORTED_1000baseT_Half     => Linux::Ethtool::Constants::SUPPORTED_1000baseT_Half,
	SUPPORTED_1000baseT_Full     => Linux::Ethtool::Constants::SUPPORTED_1000baseT_Full,
	SUPPORTED_Autoneg            => Linux::Ethtool::Constants::SUPPORTED_Autoneg,
	SUPPORTED_TP                 => Linux::Ethtool::Constants::SUPPORTED_TP,
	SUPPORTED_AUI                => Linux::Ethtool::Constants::SUPPORTED_AUI,
	SUPPORTED_MII                => Linux::Ethtool::Constants::SUPPORTED_MII,
	SUPPORTED_FIBRE              => Linux::Ethtool::Constants::SUPPORTED_FIBRE,
	SUPPORTED_BNC                => Linux::Ethtool::Constants::SUPPORTED_BNC,
	SUPPORTED_10000baseT_Full    => Linux::Ethtool::Constants::SUPPORTED_10000baseT_Full,
	SUPPORTED_Pause              => Linux::Ethtool::Constants::SUPPORTED_Pause,
	SUPPORTED_Asym_Pause         => Linux::Ethtool::Constants::SUPPORTED_Asym_Pause,
	SUPPORTED_2500baseX_Full     => Linux::Ethtool::Constants::SUPPORTED_2500baseX_Full,
	SUPPORTED_Backplane          => Linux::Ethtool::Constants::SUPPORTED_Backplane,
	SUPPORTED_1000baseKX_Full    => Linux::Ethtool::Constants::SUPPORTED_1000baseKX_Full,
	SUPPORTED_10000baseKX4_Full  => Linux::Ethtool::Constants::SUPPORTED_10000baseKX4_Full,
	SUPPORTED_10000baseKR_Full   => Linux::Ethtool::Constants::SUPPORTED_10000baseKR_Full,
	SUPPORTED_10000baseR_FEC     => Linux::Ethtool::Constants::SUPPORTED_10000baseR_FEC,

	ADVERTISED_10baseT_Half       => Linux::Ethtool::Constants::ADVERTISED_10baseT_Half,
	ADVERTISED_10baseT_Full       => Linux::Ethtool::Constants::ADVERTISED_10baseT_Full,
	ADVERTISED_100baseT_Half      => Linux::Ethtool::Constants::ADVERTISED_100baseT_Half,
	ADVERTISED_100baseT_Full      => Linux::Ethtool::Constants::ADVERTISED_100baseT_Full,
	ADVERTISED_1000baseT_Half     => Linux::Ethtool::Constants::ADVERTISED_1000baseT_Half,
	ADVERTISED_1000baseT_Full     => Linux::Ethtool::Constants::ADVERTISED_1000baseT_Full,
	ADVERTISED_Autoneg            => Linux::Ethtool::Constants::ADVERTISED_Autoneg,
	ADVERTISED_TP                 => Linux::Ethtool::Constants::ADVERTISED_TP,
	ADVERTISED_AUI                => Linux::Ethtool::Constants::ADVERTISED_AUI,
	ADVERTISED_MII                => Linux::Ethtool::Constants::ADVERTISED_MII,
	ADVERTISED_FIBRE              => Linux::Ethtool::Constants::ADVERTISED_FIBRE,
	ADVERTISED_BNC                => Linux::Ethtool::Constants::ADVERTISED_BNC,
	ADVERTISED_10000baseT_Full    => Linux::Ethtool::Constants::ADVERTISED_10000baseT_Full,
	ADVERTISED_Pause              => Linux::Ethtool::Constants::ADVERTISED_Pause,
	ADVERTISED_Asym_Pause         => Linux::Ethtool::Constants::ADVERTISED_Asym_Pause,
	ADVERTISED_2500baseX_Full     => Linux::Ethtool::Constants::ADVERTISED_2500baseX_Full,
	ADVERTISED_Backplane          => Linux::Ethtool::Constants::ADVERTISED_Backplane,
	ADVERTISED_1000baseKX_Full    => Linux::Ethtool::Constants::ADVERTISED_1000baseKX_Full,
	ADVERTISED_10000baseKX4_Full  => Linux::Ethtool::Constants::ADVERTISED_10000baseKX4_Full,
	ADVERTISED_10000baseKR_Full   => Linux::Ethtool::Constants::ADVERTISED_10000baseKR_Full,
	ADVERTISED_10000baseR_FEC     => Linux::Ethtool::Constants::ADVERTISED_10000baseR_FEC,
	
	PORT_TP    => Linux::Ethtool::Constants::PORT_TP,
	PORT_AUI   => Linux::Ethtool::Constants::PORT_AUI,
	PORT_MII   => Linux::Ethtool::Constants::PORT_MII,
	PORT_FIBRE => Linux::Ethtool::Constants::PORT_FIBRE,
	PORT_BNC   => Linux::Ethtool::Constants::PORT_BNC,
	PORT_OTHER => Linux::Ethtool::Constants::PORT_OTHER,
	
	XCVR_INTERNAL => Linux::Ethtool::Constants::XCVR_INTERNAL,
	XCVR_EXTERNAL => Linux::Ethtool::Constants::XCVR_EXTERNAL,
	XCVR_DUMMY1   => Linux::Ethtool::Constants::XCVR_DUMMY1,
	XCVR_DUMMY2   => Linux::Ethtool::Constants::XCVR_DUMMY2,
	XCVR_DUMMY3   => Linux::Ethtool::Constants::XCVR_DUMMY3,
};

use Carp;

=head2 new($dev)

Construct a new instance using the settings of the named interface.

Returns an object instance on success, undef on failure.

=cut

sub new
{
	my ($class, $dev) = @_;
	
	my $self = bless({ dev => $dev }, $class);
	
	if(_ethtool_gset($self, $dev))
	{
		return $self;
	}
	else{
		return undef;
	}
}

=head2 apply()

Apply any changed settings to the interface.

Returns true on success, false on failure.

=cut

sub apply
{
	my ($self) = @_;
	
	return _ethtool_sset($self->{dev}, $self->{advertising}, $self->{speed}, $self->{duplex}, $self->{port}, $self->{transceiver}, $self->{autoneg});
}

=head2 supported()

Returns the features supported by this interface as a bit field. The following
constants are useful here:

  SUPPORTED_TP
  SUPPORTED_AUI
  SUPPORTED_MII
  SUPPORTED_FIBRE
  SUPPORTED_BNC
  
  SUPPORTED_Autoneg
  
  SUPPORTED_10baseT_Half
  SUPPORTED_10baseT_Full
  SUPPORTED_100baseT_Half
  SUPPORTED_100baseT_Full
  SUPPORTED_1000baseT_Half
  SUPPORTED_1000baseT_Full
  SUPPORTED_2500baseX_Full
  SUPPORTED_1000baseKX_Full
  SUPPORTED_10000baseT_Full
  SUPPORTED_10000baseKX4_Full
  SUPPORTED_10000baseKR_Full
  SUPPORTED_10000baseR_FEC
  
  SUPPORTED_Pause
  SUPPORTED_Asym_Pause
  SUPPORTED_Backplane

=cut

sub supported
{
	my ($self) = @_;
	
	$self->{supported};
}

=head2 supported_modes()

Returns a sorted list of supported speed/duplex settings suitable for showing to
the user.

=cut

my @feature_mode_bits = (
	SUPPORTED_10baseT_Half,
	SUPPORTED_10baseT_Full,
	SUPPORTED_100baseT_Half,
	SUPPORTED_100baseT_Full,
	SUPPORTED_1000baseT_Half,
	SUPPORTED_1000baseT_Full,
	SUPPORTED_1000baseKX_Full,
	SUPPORTED_2500baseX_Full,
	SUPPORTED_10000baseT_Full,
	SUPPORTED_10000baseKX4_Full,
	SUPPORTED_10000baseKR_Full,
	SUPPORTED_10000baseR_FEC,
);

my %feature_mode_names = (
	&SUPPORTED_10baseT_Half       => "10baseT/Half",
	&SUPPORTED_10baseT_Full       => "10baseT/Full",
	&SUPPORTED_100baseT_Half      => "100baseT/Half",
	&SUPPORTED_100baseT_Full      => "100baseT/Full",
	&SUPPORTED_1000baseT_Half     => "1000baseT/Half",
	&SUPPORTED_1000baseT_Full     => "1000baseT/Full",
	&SUPPORTED_1000baseKX_Full    => "1000baseKX/Full",
	&SUPPORTED_2500baseX_Full     => "2500baseX/Full",
	&SUPPORTED_10000baseT_Full    => "10000baseT/Full",
	&SUPPORTED_10000baseKX4_Full  => "10000baseKX4/Full",
	&SUPPORTED_10000baseKR_Full   => "10000baseKR/Full",
	&SUPPORTED_10000baseR_FEC     => "10000baseR/FEC",
);

sub _feature_mode
{
	my ($bits) = @_;
	
	return map { $feature_mode_names{$_} } grep { $bits & $_ } @feature_mode_bits;
}

sub supported_modes
{
	my ($self) = @_;
	
	return _feature_mode($self->supported);
}

=head2 supported_ports()

Returns a list of ports on this interface suitable for showing to
the user.

B<NOTE>: This is unrelated to cards that have multiple interfaces on them, this
is for (old fashioned) cards that have multiple ports (AUI, BNC, etc) for the
same interface,only one of which may be used at a time. See the C<port> method
for more information.

=cut

my %feature_port_names = (
	&SUPPORTED_TP    => "Twisted Pair",
	&SUPPORTED_AUI   => "AUI",
	&SUPPORTED_MII   => "MII",
	&SUPPORTED_FIBRE => "Fibre",
	&SUPPORTED_BNC   => "BNC",
);

sub supported_ports
{
	my ($self) = @_;
	
	return map { $feature_port_names{$_} } grep { $self->supported & $_ } keys(%feature_port_names);
}

=head2 advertising([ $advertising ])

Gets or sets the modes being advertised for auto-negotiation as a bit field.
Returns the current/new value.

The following constants are useful here:

  ADVERTISED_10baseT_Half
  ADVERTISED_10baseT_Full
  ADVERTISED_100baseT_Half
  ADVERTISED_100baseT_Full
  ADVERTISED_1000baseT_Half
  ADVERTISED_1000baseT_Full
  ADVERTISED_2500baseX_Full
  ADVERTISED_1000baseKX_Full
  ADVERTISED_10000baseT_Full
  ADVERTISED_10000baseKX4_Full
  ADVERTISED_10000baseKR_Full
  ADVERTISED_10000baseR_FEC
  ADVERTISED_Pause
  ADVERTISED_Asym_Pause

=cut

sub advertising
{
	my ($self, $advertising) = @_;
	
	if(defined($advertising))
	{
		$self->{advertising} = $advertising;
	}
	
	return $self->{advertising};
}

=head2 advertising_modes()

Returns a sorted list of advertised speed/duplex settings suitable for showing
to the user.

=cut

sub advertising_modes
{
	my ($self) = @_;
	
	return _feature_mode($self->advertising);
}

=head2 speed([ $speed ])

Get or set the link speed in Mbps. Returns the current/new value.

Setting this field will only have an effect if auto-negotiation is also disabled
before calling apply.

=cut

sub speed
{
	my ($self, $speed) = @_;
	
	if(defined($speed))
	{
		if($speed !~ m/^\d+$/)
		{
			croak("Invalid integer given for speed '$speed'");
		}
		
		if(!(grep { $speed == $_ } (10, 100, 1000, 2500, 10000)))
		{
			carp("Speed '$speed' is not one of (10, 100, 1000, 2500, 10000)");
		}
		
		$self->{speed} = int($speed);
	}
	
	return $self->{speed};
}

=head2 duplex([ $duplex ])

Get or set the duplex of the link, full is true, half is false and unknown is
undefined. Returns the current/new value.

Setting this field will only have an effect if auto-negotiation is also disabled
before calling apply.

=cut

sub duplex
{
	my ($self, $duplex) = @_;
	
	if(defined($duplex))
	{
		$self->{duplex} = ($duplex ? Linux::Ethtool::Constants::DUPLEX_FULL : Linux::Ethtool::Constants::DUPLEX_HALF);
	}
	
	if($self->{duplex} == Linux::Ethtool::Constants::DUPLEX_HALF)
	{
		return 0;
	}
	elsif($self->{duplex} == Linux::Ethtool::Constants::DUPLEX_FULL)
	{
		return 1;
	}
	else{
		return undef;
	}
}

=head2 autoneg([ $autoneg ])

Get or set the auto-negotiation flag. Returns the current/new value.

=cut

sub autoneg
{
	my ($self, $autoneg) = @_;
	
	if(defined($autoneg))
	{
		$self->{autoneg} = ($autoneg ? 1 : 0);
	}
	
	return $self->{autoneg};
}

=head2 port([ $port ])

Get or set the port type. Returns the current/new value.

The following constants are useful here:

  PORT_TP     (Twisted Pair)
  PORT_AUI
  PORT_MII    (Media Independent Interface)
  PORT_FIBRE
  PORT_BNC
  PORT_OTHER

=cut

sub port
{
	my ($self, $port) = @_;
	
	if(defined($port))
	{
		$self->{port} = int($port);
	}
	
	return $self->{port};
}

=head2 port_name()

Return a user-friendly name for the port type.

=cut

my %port_names = (
	&PORT_TP    => "Twisted Pair",
	&PORT_AUI   => "AUI",
	&PORT_MII   => "MII",
	&PORT_FIBRE => "Fibre",
	&PORT_BNC   => "BNC",
	&PORT_OTHER => "Other",
);

sub port_name
{
	my ($self) = @_;
	
	if(defined($port_names{ $self->port }))
	{
		return $port_names{ $self->port };
	}
	else{
		return "Unknown";
	}
}

=head2 transceiver([ $transceiver ])

Get or set the transceiver type. Returns the current/new value.

The following constants are useful here:

  XCVR_INTERNAL
  XCVR_EXTERNAL
  XCVR_DUMMY1
  XCVR_DUMMY2
  XCVR_DUMMY3

=cut

sub transceiver
{
	my ($self, $transceiver) = @_;
	
	if(defined($transceiver))
	{
		$self->{transceiver} = int($transceiver);
	}
	
	return $self->{transceiver};
}

=head2 transceiver_name()

Return a user-friendly name for the transceiver type.

=cut

my %transceiver_names = (
	&XCVR_INTERNAL => "Internal",
	&XCVR_EXTERNAL => "External",
);

sub transceiver_name
{
	my ($self) = @_;
	
	if(defined($transceiver_names{ $self->transceiver }))
	{
		return $transceiver_names{ $self->transceiver };
	}
	else{
		return "Unknown";
	}
}

=head2 lp_advertising()

Gets the modes being advertised for auto-negotiation by the other end of the
link as a bit field.

The following constants are useful here:

  ADVERTISED_10baseT_Half
  ADVERTISED_10baseT_Full
  ADVERTISED_100baseT_Half
  ADVERTISED_100baseT_Full
  ADVERTISED_1000baseT_Half
  ADVERTISED_1000baseT_Full
  ADVERTISED_2500baseX_Full
  ADVERTISED_1000baseKX_Full
  ADVERTISED_10000baseT_Full
  ADVERTISED_10000baseKX4_Full
  ADVERTISED_10000baseKR_Full
  ADVERTISED_10000baseR_FEC
  ADVERTISED_Pause
  ADVERTISED_Asym_Pause

=cut

sub lp_advertising
{
	my ($self) = @_;
	
	return $self->{lp_advertising};
}

=head2 lp_advertising_modes()

Returns a sorted list of speed/duplex settings advertised by the other end of
the link suitable for showing to the user.

=cut

sub lp_advertising_modes
{
	my ($self) = @_;
	
	return _feature_mode($self->lp_advertising);
}

=head1 SEE ALSO

L<Linux::Ethtool>, L<Linux::Ethtool::WOL>

=cut

1;
