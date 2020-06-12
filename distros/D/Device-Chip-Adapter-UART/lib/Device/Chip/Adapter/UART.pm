#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

package Device::Chip::Adapter::UART;

use strict;
use warnings;
use base qw( Device::Chip::Adapter );

our $VERSION = '0.02';

use Carp;

use Future;
use Future::Buffer;
use Future::IO 0.04; # ->syswrite_exactly
use IO::Termios;

=head1 NAME

C<Device::Chip::Adapter::UART> - a C<Device::Chip::Adapter> implementation for
serial devices

=head1 DESCRIPTION

This class implements the L<Device::Chip::Adapter> interface around a regular
serial port, such as a USB UART adapter, allowing an instance of a
L<Device::Chip> driver to communicate with actual chip hardware using this
adapter.

This adapter provides both the C<GPIO> and C<UART> protocols. The C<GPIO>
protocol wraps the modem control and handshaking lines. The C<UART> protocol
adds access to the transmit and receive lines by adding the L</write> and
L</read> methods.

=cut

=head1 CONSTRUCTOR

=cut

=head2 new

   $adapter = Device::Chip::Adapter::UART->new( %args )

Returns a new instance of a C<Device::Chip::Adapter::UART>.

Takes the following named arguments:

=over 4

=item dev => STRING

Path to the device node representing the UART; usually something like
F</dev/ttyUSB0> or F</dev/ttyACM0>.

=back

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   my $termios = IO::Termios->open( $args{dev} ) or
      die "Cannot open $args{dev} - $!";

   $termios->blocking( 0 );

   for( $termios->getattr ) {
      $_->cfmakeraw;
      $_->setflag_clocal( 1 );

      $termios->setattr( $_ );
   }

   return bless {
      termios => $termios,

      # protocol defaults
      bits   => 8,
      parity => "n",
      stop   => 1,
   }, $class;
}

sub new_from_description
{
   my $class = shift;
   my %args = @_;
   return $class->new( map { $_ => $args{$_} } qw( dev ) );
}

=head1 PROTOCOLS

The following C<Device::Chip::Adapter> protocol types are supported

=over 2

=item *

GPIO

=back

=cut

sub make_protocol_GPIO { return Future->done( $_[0] ) }
sub make_protocol_UART { return Future->done( $_[0] ) }

# Protocol implementation

my %GPIOS_READ = (
   DSR => 1,
   CTS => 1,
   CD  => 1,
   RI  => 1,
);

sub configure
{
   my $self = shift;
   my %args = @_;

   exists $args{$_} and $self->{$_} = delete $args{$_}
      for qw( baudrate bits parity stop );

   keys %args and
      croak "Unrecognised configure options: " . join( ", ", keys %args );

   $self->{termios}->set_mode( join ",",
      @{$self}{qw( baudrate bits parity stop )}
   );

   return Future->done;
}

sub list_gpios
{
   return qw( DTR DSR RTS CTS CD RI );
}

sub meta_gpios
{
   return map {
      $GPIOS_READ{$_} ?
         Device::Chip::Adapter::GPIODefinition( $_, "r", 1 ) :
         Device::Chip::Adapter::GPIODefinition( $_, "w", 1 );
   } shift->list_gpios;
}

sub read_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my $values = $self->{termios}->get_modem();

   my %ret;

   foreach my $gpio ( @$gpios ) {
      $ret{$gpio} = $values->{lc $gpio} if $GPIOS_READ{$gpio};
   }

   return Future->done( \%ret );
}

sub write_gpios
{
   my $self = shift;
   my ( $gpios ) = @_;

   my %set;
   defined $gpios->{$_} and $set{lc $_} = $gpios->{$_}
      for qw( DTR RTS );

   if( %set ) {
      $self->{termios}->set_modem( \%set );
   }

   return Future->done;
}

sub tris_gpios
{
   # ignore
   Future->done;
}

sub write
{
   my $self = shift;
   my ( $bytes ) = @_;

   return Future::IO->syswrite_exactly( $self->{termios}, $bytes );
}

sub readbuffer
{
   my $self = shift;
   return $self->{readbuf} //= do {
      my $fh  = $self->{termios};

      Future::Buffer->new(
         fill => sub { Future::IO->sysread( $fh, 256 ) },
      );
   };
}

sub read
{
   my $self = shift;
   my ( $len ) = @_;

   # This is a 'read_exactly'
   return $self->readbuffer->read_exactly( $len );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
