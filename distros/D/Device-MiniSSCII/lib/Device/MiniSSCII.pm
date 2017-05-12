package Device::MiniSSCII;
use strict;
use Carp;

our $VERSION = $VERSION = (qw($Revision: 1.2 $))[1];

=head1 NAME

Device::MiniSSCII - Perl device driver for the Mini SSC II serial servo controller

=head1 SYNOPSIS

  my $ssc = Device::MiniSSCII->new(
				device => '/dev/ttyS0',
				baudrate => 9600
				);
  $ssc->move( 0, 100 );
  $ssc->close;

=head1 DESCRIPTION

This module implements a driver for the Mini SSC II servo controller from Scott Edwards Electronics Inc (http://www.seetron.com/ssc.htm).

=cut

use base 'Class::Accessor';
__PACKAGE__->mk_accessors(qw(device baudrate _sp));

use Device::SerialPort;

=head1 METHODS

=head2 B<new> - constructor

 my $ssc = Device::MiniSSCII->new(
				device => '/dev/ttyS0',
				baudrate => 9600
				)

The constructor expects two arguments, a C<device> that denotes the serial port and a C<baudrate> that can be either C<2400> or C<9600>.

=cut

sub new {
	my ($proto, %arg) = @_;
	my $self = bless {}, ref($proto) || $proto;

	die "I need a device" unless defined $arg{device};
	die "I need a baudrate" unless defined $arg{baudrate};

	$self->device( $arg{device} );
	$self->baudrate( $arg{baudrate} );

	my $sp = Device::SerialPort->new( $self->device, 1 )
		|| die "Could not open serial port on " . $self->device;

	$sp->baudrate( $self->baudrate ) || die "Could not set baudrate";
	$sp->databits(8) || die "Could set 8 databits";
	$sp->parity("none") || die "Could not set parity to 'none'";
	$sp->stopbits(1) || die "Could not set stopbits to 1";
	$sp->handshake("none") || die "Could not set handshake to 'none'";	
	$sp->write_settings || die "Could not activate settings";
	$self->_sp( $sp );

	return $self;
}

=head2 B<move> - Set the position of a servo

  $ssc->move( 0, 128 );

This method sets the position of a servo. The first argument is the servo number, in the range from 0 to 255. The second parameter represents the position to set the servo to, also in the range from 0 to 255.

=cut

sub move {
	my ($self, $servo, $position) = @_;

	my $count = $self->_sp->write(pack("C*", 255, $servo, $position));
	carp "Error moving servo $servo to position $position." if $count != 3;
	
	return $self;
}

=head2 B<close> - Close serial connection and clean-up

  $ssc->close;

=cut

sub close {
	my ($self) = @_;

	$self->_sp->close;
}

1;

__END__

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>

