#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.70;

package Device::Chip::Adapter::UART 0.03;
class Device::Chip::Adapter::UART;

# Can't isa Device::Chip::Adapter because it doesn't have a 'new'
use Device::Chip::Adapter;
*make_protocol = \&Device::Chip::Adapter::make_protocol;

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

As the C<Device::Chip> interface is intended for hardware IO interfaces, it
does not support the concept that a serial stream might spontaneously become
disconnected. As such, an end-of-file condition on the stream filehandle will
be reported as a future failure.

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

field $_fh;
field %_config = (
   bits   => 8,
   parity => "n",
   stop   => 1,
);

ADJUST :params (
   :$fh = undef,
   :$dev = undef,
) {
   if( defined $fh ) {
      $_fh = $fh;
      # OK
   }
   else {
      $_fh = IO::Termios->open( $dev ) or
         die "Cannot open $dev - $!";

      $_fh->blocking( 0 );

      for( $_fh->getattr ) {
         $_->cfmakeraw;
         $_->setflag_clocal( 1 );

         $_fh->setattr( $_ );
      }
   }
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

method configure ( %args )
{
   exists $args{$_} and $_config{$_} = delete $args{$_}
      for qw( baudrate bits parity stop );

   keys %args and
      croak "Unrecognised configure options: " . join( ", ", keys %args );

   $_fh->set_mode( join ",",
      @_config{qw( baudrate bits parity stop )}
   );

   return Future->done;
}

method power ( $ ) { return Future->done } # ignore

method list_gpios ()
{
   return qw( DTR DSR RTS CTS CD RI );
}

method meta_gpios ()
{
   return map {
      $GPIOS_READ{$_} ?
         Device::Chip::Adapter::GPIODefinition( $_, "r", 1 ) :
         Device::Chip::Adapter::GPIODefinition( $_, "w", 1 );
   } shift->list_gpios;
}

method read_gpios ( $gpios )
{
   my $values = $_fh->get_modem();

   my %ret;

   foreach my $gpio ( @$gpios ) {
      $ret{$gpio} = $values->{lc $gpio} if $GPIOS_READ{$gpio};
   }

   return Future->done( \%ret );
}

method write_gpios ( $gpios )
{
   my %set;
   defined $gpios->{$_} and $set{lc $_} = $gpios->{$_}
      for qw( DTR RTS );

   if( %set ) {
      $_fh->set_modem( \%set );
   }

   return Future->done;
}

method tris_gpios ( $ )
{
   # ignore
   Future->done;
}

method write ( $bytes )
{
   return Future::IO->syswrite_exactly( $_fh, $bytes );
}

field $_readbuf;
method readbuffer ()
{
   return $_readbuf //= do {
      my $fh = $_fh;

      Future::Buffer->new(
         fill => sub { Future::IO->sysread( $fh, 256 ) },
      );
   };
}

method read ( $len )
{
   # This is a 'read_exactly'
   return $self->readbuffer->read_exactly( $len )
      ->then( sub { return @_ ? Future->done( @_ ) : Future->fail( "EOF" ) } );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
