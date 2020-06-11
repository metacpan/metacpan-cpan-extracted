#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2018 -- leonerd@leonerd.org.uk

package Device::Chip::Adapter;

use strict;
use warnings;

use utf8;

our $VERSION = '0.13';

use Carp;

use Struct::Dumb qw( readonly_struct );

require Device::Chip;

=encoding UTF-8

=head1 NAME

C<Device::Chip::Adapter> - an abstraction of a hardware communication device

=head1 DESCRIPTION

This package describes an interfaces tha classes can use to implement a driver
to provide access to some means of connecting an electronic chip or hardware
module to a computer. An instance implementing this interface provides some
means to send electrical signals to a connected chip or module, and receive
replies back from it; this device is called the I<adapter>. This is provided
as a service to some instance of the related interface, L<Device::Chip>.

It is suggested that a driver for a particular adapter provides a concrete
class named within the C<Device::Chip::Adapter> heirarchy, adding the basic
name of the product or means of communication as a suffix; for example the
driver for communication device based on the I<FDTI> range of devices would
be called:

   package Device::Chip::Adapter::FTDI;

This package provides a base class that such a specific implementation class
could use as a superclass, but it is not required to. The important detail is
that it provides the interface described by this documentation.

=cut

=head1 UTILITY CONSTRUCTOR

=cut

=head2 new_from_description

   $adapter = Device::Chip::Adapter->new_from_description( $DESC )

This utility method is provided to allow end-user programs a convenient way to
construct a useable C<Device::Chip::Adapter> instance from a given single
string value. This string takes the form of a the main name of the adapter
class (minus the leading C<Device::Chip::Adapter::> prefix), optionally
followed by a single colon and some comma-separated options. Each option takes
the form of a name and value, separated by equals sign. For example:

   FTDI
   FTDI:
   FTDI:product=0x0601
   BusPirate:serial=/dev/ttyUSB3,baud=57600

This utility method splits off the base name from the optional suffix, and
splits the options into an even-sized name/value list. It loads the class
implied by the base name and invokes a method called C<new_from_description>
on it. This is passed the even-sized name/value list obtained by splitting
the option string. Any option named without a value will be passed having the
value C<1>, as a convenience for options that are simple boolean flags.

If the class does not provide the C<new_from_description> method (and of
course, simply inheriting the base class one from here does not count), then
if there are no other options given, the plain C<new> constructor is invoked
instead. If this is not possible because there are user-specified options that
must be honoured, then an exception is thrown instead.

Note for example that in the case above, the C<product> option would be passed
to the C<FTDI> adapter class still as a string value; it is likely that this
class would want to implement a C<new_from_description> method to parse that
using the C<oct> operator into a plain integer.

It is intended that this method is used for creating an adapter that a
standalone program can use from a description string specified by the user;
likely in a commandline option or environment variable.

If I<$DESC> is undefined, a default value is taken from the environment
variable C<DEVICE_CHIP_ADAPTER>, if defined. If not, an exception is thrown.

=cut

sub new_from_description
{
   shift;
   my ( $description ) = @_;

   defined( $description //= $ENV{DEVICE_CHIP_ADAPTER} ) or
      croak "Undefined Device::Chip adapter description";

   my ( $basename, $opts ) = $description =~ m/^([^:]+)(?::(.*))?$/ or
      croak "Malformed adapter description - $description";

   # Not a hash, in case the same option is given more than once
   my @opts = Device::Chip->_parse_options( $opts );

   my $class = "Device::Chip::Adapter::$basename";
   ( my $file = "$class.pm" ) =~ s{::}{/}g;

   require $file;

   my $code = $class->can( "new_from_description" );
   if( $code and $code != \&new_from_description ) {
      return $class->$code( @opts );
   }
   elsif( !@opts ) {
      # Fall back on plain ->new
      return $class->new();
   }

   croak "$class does not provide a ->new_from_description and we cannot fallback on ->new with options";
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

=head2 make_protocol

   $protocol = $adapter->make_protocol( $pname )->get

Returns an object that satisfies one of the interfaces documented below in
L</PROTOCOLS>, depending on the protocol name given by I<$pname>. This should
be one of the following values:

   GPIO
   SPI
   I2C

It is unspecified what class these objects should belong to. In particular, it
is permitted that an adapter could even return itself as the protocol
implementation, provided it has the methods to satisfy the interface for that
particular protocol. This is especially convenient in the case that the
adapter is only capable of one kind of protocol.

=cut

# A default implementation that uses some reflection to simplify
# implementations
sub make_protocol
{
   my $self = shift;
   my ( $pname ) = @_;

   if( my $code = $self->can( "make_protocol_$pname" ) ) {
      return $code->( $self );
   }
   else {
      croak "Unrecognised protocol name $pname";
   }
}

=head2 shutdown

   $adapter->shutdown

Shuts down the adapter in whatever manner is appropriate at the end of the
lifetime of the containing program; or at least, at the point when the program
has finished using the connected device.

This method is allowed to block; it does not yield a L<Future>. It is suitable
to call from a C<DESTROY> method or C<END> block.

=cut

=head1 PROTOCOLS

The following methods are common to all protocol instances:

=head2 sleep

   $protocol->sleep( $secs )->get

Causes a fixed delay, given in (fractional) seconds. Adapter module authors
should attempt to perform this delay concurrently, overlapping IO with other
operations where possible.

=head2 configure

   $protocol->configure( %args )->get

Sets configuration options for the protocol. The actual set of options
available will depend on the type of the protocol.

Chip drivers should attempt to bundle their changes together into as few
C<configure> calls as possible, because adapters may find it most efficient to
apply multiple changes in one go.

=head2 power

   $protocol->power( $on )->get

Switches on or off the power to the actual chip or module, if such ability is
provided by the adapter.

=head2 list_gpios

   @pin_names = $protocol->list_gpios

Returns a list of the names of GPIO pins that are available for the chip
driver to use. This list would depend on the pins available on the adapter
itself, minus any pins that are in use by the protocol itself.

Adapters should name GPIO pins in a way that makes sense from the hardware;
for example C<MOSI>, C<SDA>, C<DTR>, C<Q0>, etc...

=head2 meta_gpios

   @pin_definitions = $protocol->meta_gpios

Returns a list of definition objects that define the behavior of the GPIO
pins. This should be returned in the same order as the L</list_gpios> method.

Each returned value will be an instance with the following methods:

=over 4

=item name

   $def->name = STR

Gives the device's name for that GPIO pin - the name that would be returned
by L</list_gpios> and recognised by the other methods.

=item dir

   $def->dir = "r" | "w" | "rw"

Gives the data directions that the GPIO pin supports. C<r> for pins that are
read-only, C<w> for pins that are write-only, and C<rw> for pins that are
bidirectional.

=item invert

   $def->invert = BOOL

If true, the hardware itself will invert the sense of reads or writes to this
pin - that is, a low voltage on the pin will be represented by a true value in
the L</write_gpios> and L</read_gpios> methods, and a high voltage represented
by a false value.

=back

Adapter implementations may wish to use a L<Struct::Dumb> definition provided
by this package, called L<Device::Chip::Adapter::GPIODefinition> to implement
these.

=cut

readonly_struct GPIODefinition => [qw( name dir invert )];

=head2 write_gpios

   $protocol->write_gpios( \%pin_values )->get

Sets the named GPIO pins as driven outputs, and gives their new values. Any
GPIO pins not named are left as they are; either driving outputs at the
current state, or high-impedence inputs.

Pins are specified as a C<HASH> reference, mapping pin names (as returned by
the L</list_gpios> method) to boolean logic levels.

=head2 read_gpios

   \%pin_values = $protocol->read_gpios( \@pin_names )->get;

Sets the named GPIO pins as high-impedence inputs, and reads their current
state. Any GPIO pins not named here are left as they are; either driving
outputs at the current state, or other inputs.

Pins are specified in an C<ARRAY> reference giving the names of pins (as
returned by the L</list_gpios> method); read values are given in the returned
C<HASH> reference which maps pin names to boolean logic levels.

=head2 tris_gpios

   $protocol->tris_gpios( \@pin_names )->get;

Sets the named GPIO pins as high-impedence inputs ("tristate"). Any GPIO pins
not named here are left as they are.

This method is similar to L</read_gpios> except that it does not return the
current pin values to the caller. Adapter implementations may implement this
by simply calling L</read_gpios> or they may have a more efficient variant
that does not have to transfer these extra readings back from the adapter
hardware.

=cut

=head1 GPIO PROTOCOL

The GPIO protocol adds no new abilities or methods; it is the most basic form
of protocol that simply provides access to the generic GPIO pins of the
device.

=head1 SPI PROTOCOL

=head2 Configuration Options

The following configuration options are recognised:

=over 4

=item mode => 0 | 1 | 2 | 3

The numbered SPI mode used to communicate with the chip.

=item max_bitrate => INT

The highest speed, in bits per second, that the chip can accept. The adapter
must pick a rate that is no higher than this. Note specifically that not all
adapters are able to choose a rate arbitrarily, and so the actually
communication may happen at some rate slower than this.

=item wordsize => INT

The number of bits per word transferred. Many drivers will not be able to
accept a number other than 8.

For values less than 8, the value should be taken from the least-significant
bits of each byte given to the C<readwrite> or C<write> methods.

For values greater than 8, use character strings with wide codepoints inside;
such as created by the C<chr()> function.

=back

=head2 readwrite

   $words_in = $spi->readwrite( $words_out )->get

Performs a complete SPI transaction; assert the SS pin, synchronously clock
the data given by the I<$words_out> out of the MOSI pin of the adapter while
simultaneously capturing the data coming in to the MISO pin, then release the
SS pin again. The values clocked in are eventually returned as the result of
the returned future.

=head2 write

   $spi->write( $words )->get

A variant of C<readwrite> where the caller does not intend to make use of the
data returned by the device, and so the adapter does not need to return it.
This may or may not make a material difference to the actual communication
with the adapter or device; it could be implemented simply by calling the
C<readwrite> method and ignoring the return value.

=head2 read

   $words = $spi->read( $len )->get

A variant of C<readwrite> where the chip will not care what data is written
to it, so the caller does not need to supply it. This may or may not make a
material difference to the actual communication with the adapter or device;
it could be implemented simply by calling the C<readwrite> method and passing
in some constant string of appropriate length.

=head2 write_then_read

    $words_in = $spi->write_then_read( $words_out, $len_in )->get

Performs a complete SPI transaction; assert the SS pin, synchronously clock
the data given by I<$words_out> out of the MOSI pin of the adapter, then clock
in more data from the MISO pin, finally releasing the SS pin again. These two
operations must be performed within a single assert-and-release SS cycle. It
is unspecified what values will be sent out during the read phase; adapters
should typically send all-bits-low or all-bits-high, but in general may not
allow configuration of what that will be.

This differs from the C</readwrite> method in that it works sequentially;
sending out words while ignoring the result, then reading in words while
sending unspecified data.

=head2 assert_ss

=head2 release_ss

   $spi->assert_ss->get

   $spi->release_ss->get

Lower-level access methods to directly assert or release the SS pin of the
adapter. These would typically be used in conjunction with L</readwrite_no_ss>
or L</write_no_ss>.

=head2 readwrite_no_ss

=head2 write_no_ss

=head2 read_no_ss

   $words_in = $spi->readwrite_no_ss( $words_out )->get

   $spi->write_no_ss( $words )->get

   $words = $spi->read_no_ss( $len )->get

Lower-level access methods to directly perform a data transfer across the
MOSI/MISO pins of the adapter, without touching the SS pin. A complete SPI
transaction can be performed in conjunction with the L</assert_ss> and
L</release_ss> methods.

   $spi->assert_ss
      ->then( sub {
         $spi->readwrite_no_ss( $words_out );
      })
      ->then( sub {
         ( $words_in ) = @_;
         $spi->release_ss->then_done( $words_in );
      });

These methods are provided for situations where it is not possible to know in
advance all the data to be sent out in an SPI transaction; where the chip
driver code must inspect some of the incoming data before it can determine
what else needs to be sent, but when these must all be sent in one SS-asserted
transaction.

Because they perform multiple independent operations on the underlying
adapter, these lower-level methods may be less efficient than using the single
higher-level methods of L</readwrite> and L</write>. As such, they should only
be used when the combined higher-level method cannot be used.

Note that many of these methods can be synthesized from other simpler ones. A
convenient abstract base class, L<Device::Chip::ProtocolBase::SPI>, can be
used to do this, providing wrappers for some methods implemented using others.
This reduces the number of distinct methods that need to be provided.
Implementations may still, and are encouraged to, provide "better" versions of
those methods if they can be provided more efficiently than simply wrapping
others.

=cut

=head1 I2C PROTOCOL

=head2 Configuration Options

The following configuration options are recognised:

=over 4

=item addr => INT

The (7-bit) slave address for the chip this protocol is communicating with.

=item max_bitrate => INT

The highest speed, in bits per second, that the chip can accept. The adapter
must pick a rate that is no higher than this. Note specifically that not all
adapters are able to choose a rate arbitrarily, and so the actually
communication may happen at some rate slower than this.

=back

=head2 write

    $i2c->write( $bytes_out )->get

Performs a complete I²C transaction to send the given bytes to the slave chip.
This includes the start condition, sending the addressing byte (which is
implied; it should I<not> be included in C<$bytes_out>) and ending in the stop
condition.

=head2 read

    $bytes_in = $i2c->read( $len_in )->get

Performs a complete I²C transaction to receive the given number of bytes back
from the slave chip. This includes the start condition, sending the addressing
byte and ending in a stop condition.

=head2 write_then_read

    $bytes_in = $i2c->write_then_read( $bytes_out, $len_in )->get

Performs a complete I²C transaction to first send the given bytes to the slave
chip then reads the give number of bytes back, returning them. These two
operations must be performed within a single I²C transaction using a repeated
start condition.

=cut

=head1 UART PROTOCOL

The UART protocol is still subject to ongoing design. In particular, a
suitable interface for general-purpose spurious read notifications ha yet to
be designed. The current API is suitable for transmit-only, or
request/response interfaces where the PC side is in control of communications
and knows exactly when, and how many bytes long, data will be received.

=head2 Configuration Options

=over 4

=item baudrate => INT

The communication bitrate, in bits per second. Most adapters ought to be able
to accept the common ones such as 9600, 19200 or 38400.

=item bits => INT

The number of bits per character. Usually 8, though some adapters may be able
to offer smaller values.

=item parity => "n" | "o" | "e"

Disables parity generation/checking (when C<n>), or enables it for odd
(when C<o>) or even (when C<e>).

=item stop => 1 | 2

The size of the stop state, in bits. Either 1 or 2.

=back

=head2 write

   $uart->write( $bytes )->get

Transmits the given bytes over the UART TX line.

=head2 read

   $bytes = $uart->read( $len )->get

Receives the given number of bytes from the UART RX line. The returned future
will not complete until the requested number of bytes are available.

This API is suitable for PC-first request/response style interfaces, but will
not be sufficient for chip-first notifications or other use-cases. A suitable
API shape for more generic scenarios is still a matter of ongoing design
investigation.

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
