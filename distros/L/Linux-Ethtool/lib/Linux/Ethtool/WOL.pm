=head1 NAME

Linux::Ethtool::WOL - Manipulate interface Wake-on-LAN settings

=head1 SYNOPSIS

  use Linux::Ethtool::WOL qw(:all);
  
  my $wol = Linux::Ethtool::WOL->new("eth0") or die($!);
  
  unless($wol->supported & WAKE_MAGIC)
  {
	  die("Network card does not support WOL using Magic Packet");
  }
  
  $wol->wolopts(WAKE_MAGIC);
  
  $wol->apply() or die($!);

=head1 DESCRIPTION

This module provides a wrapper around the C<ethtool_wolinfo> structure and
associated ioctls, used for configuring Wake-on-LAN options.

All the constants in this module may be imported individually or by using the
C<all> import tag.

=head1 METHODS

=cut

package Linux::Ethtool::WOL;

use strict;
use warnings;

our $VERSION = "0.11";

require XSLoader;
XSLoader::load("Linux::Ethtool::WOL");

use Exporter qw(import);

our @EXPORT_OK = qw(
	WAKE_PHY
	WAKE_UCAST
	WAKE_MCAST
	WAKE_BCAST
	WAKE_ARP
	WAKE_MAGIC
	WAKE_MAGICSECURE
);

our %EXPORT_TAGS = (
	all => [ @EXPORT_OK ],
);

use Linux::Ethtool::Constants;

# Duplicate the constants here so we can export them.

use constant {
	WAKE_PHY         => Linux::Ethtool::Constants::WAKE_PHY,
	WAKE_UCAST       => Linux::Ethtool::Constants::WAKE_UCAST,
	WAKE_MCAST       => Linux::Ethtool::Constants::WAKE_MCAST,
	WAKE_BCAST       => Linux::Ethtool::Constants::WAKE_BCAST,
	WAKE_ARP         => Linux::Ethtool::Constants::WAKE_ARP,
	WAKE_MAGIC       => Linux::Ethtool::Constants::WAKE_MAGIC,
	WAKE_MAGICSECURE => Linux::Ethtool::Constants::WAKE_MAGICSECURE,
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
	
	if(_ethtool_gwol($self, $dev))
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
	
	return _ethtool_swol($self->{dev}, $self->{wolopts}, $self->{sopass});
}

=head2 supported()

Return the supported WOL flags which is any of the following constants bitwise
OR'd together:

  WAKE_PHY
  WAKE_UCAST
  WAKE_MCAST
  WAKE_BCAST
  WAKE_ARP
  WAKE_MAGIC
  WAKE_MAGICSECURE

=cut

sub supported
{
	my ($self) = @_;
	
	return $self->{supported};
}

=head2 wolopts([ $wolopts ])

Get or set the enabled WOL options, these should be a subset of those returned
by C<supported>.

Returns the current/new value.

=cut

sub wolopts
{
	my ($self, $wolopts) = @_;
	
	if(defined($wolopts))
	{
		$self->{wolopts} = $wolopts;
	}
	
	return $self->{wolopts};
}

=head2 sopass([ $sopass ])

Get or set the SecureOn(TM) password, only meaningful if the C<WAKE_MAGICSECURE>
flag is set, which itself requires C<WAKE_MAGIC>.

The value is a scalar which is 6 B<BYTES> (not characters) long.

=cut

sub sopass
{
	my ($self, $sopass) = @_;
	
	if(defined($sopass))
	{
		use bytes;
		
		if(length($sopass) != 6)
		{
			croak("sopass must be 6 BYTES long");
		}
		
		$self->{sopass} = $sopass;
	}
	
	return $self->{sopass};
}

=head1 SEE ALSO

L<Linux::Ethtool>, L<Linux::Ethtool::Settings>

=cut

1;
