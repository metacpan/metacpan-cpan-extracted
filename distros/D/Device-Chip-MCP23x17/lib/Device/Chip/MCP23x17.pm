#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package Device::Chip::MCP23x17;

use strict;
use warnings;
use base qw( Device::Chip );

our $VERSION = '0.01';

=head1 NAME

C<Device::Chip::MCP23x17> - chip driver for the F<MCP23x17> family

=head1 SYNOPSIS

 use Device::Chip::MCP23S17;

 use constant { HIGH => 0xFFFF, LOW => 0 };

 my $chip = Device::Chip::MCP23S17->new;
 $chip->mount( Device::Chip::Adapter::...->new )->get;

 foreach my $bit ( 0 .. 15 ) {
    $chip->write_gpio( HIGH, 1 << $bit )->get;
    sleep 1;
    $chip->write_gpio( LOW, 1 << $bit )->get;
 }

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to the
F<Microchip> F<MCP23x17> family of chips.

This module itself is an abstract base; to talk to a specific chip see
one of the following subclasses:

=over 4

F<MCP23S17> over SPI - see L<Device::Chip::MCP23S17>

=back

Aside from the method of communication with the actual chip hardware, these
modules all provide the same higher-level API to the containing application.

This module currently only supports a chip running in the C<IOCON.BANK=0>
configuration.

=cut

sub new
{
   my $class = shift;
   my $self = $class->SUPER::new( @_ );

   $self->reset;

   return $self;
}

=head1 MOUNT PARAMETERS

=head2 reset

The name of the GPIO line on the adapter that is connected to the C<RESET#>
pin of the chip, if there is one. This will be used by the L</reset> method.

=cut

sub mount
{
   my $self = shift;
   my ( $adapter, %params ) = @_;

   $self->{reset} = delete $params{reset};

   return $self->SUPER::mount( @_ );
}

use constant {
   # Register allocations when in IOCON.BANK=0 mode
   #   TODO: we don't yet support BANK=1 mode
   REG_IODIR   => 0x00,
   REG_IPOL    => 0x02,
   REG_GPINTEN => 0x04,
   REG_DEFVAL  => 0x06,
   REG_INTCON  => 0x08,
   REG_IOCON   => 0x0A,
   REG_GPPU    => 0x0C,
   REG_INTF    => 0x0E,
   REG_INTCAP  => 0x10,
   REG_GPIO    => 0x12,
   REG_OLAT    => 0x14,
};

sub _cached_maskedwrite_u16
{
   my $self = shift;
   my ( $name, $val, $mask ) = @_;

   my $want = ( $self->{$name} & ~$mask ) | ( $val & $mask );

   return Future->done if ( my $got = $self->{$name} ) == $want;
   $self->{$name} = $want;

   my $reg = __PACKAGE__->can( "REG_\U$name" )->();

   if( ( $got & 0xFF00 ) == ( $want & 0xFF00 ) ) {
      # low-byte write
      $self->write_reg( $reg, pack "C", $want & 0x00FF );
   }
   elsif( ( $got & 0x00FF ) == ( $want & 0x00FF ) ) {
      $self->write_reg( $reg+1, pack "C", ( $want & 0xFF00 ) >> 8 );
   }
   else {
      $self->write_reg( $reg, pack "S<", $want );
   }
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

Each method that takes a C<$mask> parameter uses it to select which IO pins
are affected. The mask is a 16-bit integer; selecting only those pins for
which bits are set. The lower 8 bits relate to the C<GPA> pins, the higher 8
to the C<GPB> pins. Pins that are not selected by the mask remain unaffected.

=cut

=head2 reset

   $chip->reset->get;

Resets the cached register values back to their power-up defaults.

Additionally, if the C<reset> mount parameter is defined, pulses the C<RESET#>
pin of the chip.

=cut

sub reset
{
   my $self = shift;

   # Default registers
   $self->{iodir} = 0xffff;
   $self->{olat}  = 0x0000;
   $self->{ipol}  = 0x0000;
   $self->{gppu}  = 0x0000;

   if( defined( my $reset = $self->{reset} ) ) {
      $self->protocol->write_gpios( { $reset => 0 } )->then( sub {
         $self->protocol->write_gpios( { $reset => 1 } );
      });
   }
   else {
      Future->done;
   }
}

=head2 write_gpio

   $chip->write_gpio( $val, $mask )->get

Sets the pins named in the C<$mask> to be outputs, and sets their values from
the bits in C<$val>. Both values are 16-bit integers.

=cut

sub write_gpio
{
   my $self = shift;
   my ( $val, $mask ) = @_;

   Future->needs_all(
      # Write the values before the direction, so as not to cause glitches
      $self->_cached_maskedwrite_u16( olat  => $val,   $mask ),
      $self->_cached_maskedwrite_u16( iodir => 0x0000, $mask ),
   );
}

=head2 read_gpio

   $val = $chip->read_gpio( $mask )->get

Sets the pins named in the C<$mask> to be inputs, and reads the current pin
values of them. The mask and the return value are 16-bit integers.

=cut

sub read_gpio
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->tris_gpio( $mask )->then( sub {
      $self->read_reg( REG_GPIO, 2 )
   })->transform( done => sub {
      my $val = unpack "S<", $_[0];
      $val & $mask;
   });
}

=head2 tris_gpio

   $chip->tris_gpio( $mask )

Sets the pins named in the C<$mask> to be inputs ("tristate"). The mask is a
16-bit integer.

=cut

sub tris_gpio
{
   my $self = shift;
   my ( $mask ) = @_;

   $self->_cached_maskedwrite_u16( iodir => 0xFFFF, $mask );
}

=head2 set_input_polarity

   $chip->set_input_polarity( $pol, $mask )

Sets the input polarity of the pins given by C<$mask> to be the values given
in C<$pol>. Pins associated with bits set in C<$pol> will read with an
inverted sense. Both values are 16-bit integers.

=cut

sub set_input_polarity
{
   my $self = shift;
   my ( $pol, $mask ) = @_;

   $self->_cached_maskedwrite_u16( ipol => $pol, $mask );
}

=head2 set_input_pullup

   $chip->set_input_pullup( $pullup, $mask )

Enables or disables the input pullup resistors on the pins given by C<$mask>
as per the values given by C<$pullup>. Both values are 16-bit integers.

=cut

sub set_input_pullup
{
   my $self = shift;
   my ( $pullup, $mask ) = @_;

   $self->_cached_maskedwrite_u16( gppu => $pullup, $mask );
}

=head1 TODO

=over 4

=item *

Wrap the interrupt-related registers - C<GPINTEN>, C<DEFVAL>, C<INTCON>,
C<INTF>, C<INTCAP>. Support the interrupt-related bits in C<IOCON> -
C<MIRROR>, C<ODR>, C<INTPOL>.

=item *

Support the general configuration bits in the C<IOCON> register - C<DISSLW>,
C<HAEN>.

=item *

Consider how easy/hard or indeed how useful it might be to support
C<IOCON.BANK=1> configuration.

=item *

Create a L<Device::Chip::Adapter> instance to represent the GPIO pins as a
standard adapter.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
