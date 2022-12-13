#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015-2022 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.66;

package Device::Chip::MCP23x17 0.06;
class Device::Chip::MCP23x17
   :isa(Device::Chip);

use Future::AsyncAwait;

=head1 NAME

C<Device::Chip::MCP23x17> - chip driver for the F<MCP23x17> family

=head1 SYNOPSIS

   use Device::Chip::MCP23S17;
   use Future::AsyncAwait;

   use constant { HIGH => 0xFFFF, LOW => 0 };

   my $chip = Device::Chip::MCP23S17->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   foreach my $bit ( 0 .. 15 ) {
      await $chip->write_gpio( HIGH, 1 << $bit );
      sleep 1;
      await $chip->write_gpio( LOW, 1 << $bit );
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

ADJUST
{
   $self->reset;
}

=head1 MOUNT PARAMETERS

=head2 reset

The name of the GPIO line on the adapter that is connected to the C<RESET#>
pin of the chip, if there is one. This will be used by the L</reset> method.

=cut

field $_resetpin;

async method mount ( $adapter, %params )
{
   $_resetpin = delete $params{reset};

   return await $self->SUPER::mount( $adapter, %params );
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

field %_regcache;

async method _cached_maskedwrite_u16 ( $name, $val, $mask )
{
   my $want = ( $_regcache{$name} & ~$mask ) | ( $val & $mask );

   return if ( my $got = $_regcache{$name} ) == $want;
   $_regcache{$name} = $want;

   my $reg = __PACKAGE__->can( "REG_\U$name" )->();

   if( ( $got & 0xFF00 ) == ( $want & 0xFF00 ) ) {
      # low-byte write
      await $self->write_reg( $reg, pack "C", $want & 0x00FF );
   }
   elsif( ( $got & 0x00FF ) == ( $want & 0x00FF ) ) {
      await $self->write_reg( $reg+1, pack "C", ( $want & 0xFF00 ) >> 8 );
   }
   else {
      await $self->write_reg( $reg, pack "S<", $want );
   }
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

Each method that takes a C<$mask> parameter uses it to select which IO pins
are affected. The mask is a 16-bit integer; selecting only those pins for
which bits are set. The lower 8 bits relate to the C<GPA> pins, the higher 8
to the C<GPB> pins. Pins that are not selected by the mask remain unaffected.

=cut

=head2 reset

   await $chip->reset;

Resets the cached register values back to their power-up defaults.

Additionally, if the C<reset> mount parameter is defined, pulses the C<RESET#>
pin of the chip.

=cut

async method reset
{
   # Default registers
   $_regcache{iodir} = 0xffff;
   $_regcache{olat}  = 0x0000;
   $_regcache{ipol}  = 0x0000;
   $_regcache{gppu}  = 0x0000;

   if( defined( my $reset = $_resetpin ) ) {
      await $self->protocol->write_gpios( { $reset => 0 } );
      await $self->protocol->write_gpios( { $reset => 1 } );
   }
}

=head2 write_gpio

   await $chip->write_gpio( $val, $mask );

Sets the pins named in the C<$mask> to be outputs, and sets their values from
the bits in C<$val>. Both values are 16-bit integers.

=cut

async method write_gpio ( $val, $mask )
{
   # Write the values before the direction, so as not to cause glitches
   await $self->_cached_maskedwrite_u16( olat  => $val,   $mask ),
   await $self->_cached_maskedwrite_u16( iodir => 0x0000, $mask ),
}

=head2 read_gpio

   $val = await $chip->read_gpio( $mask );

Sets the pins named in the C<$mask> to be inputs, and reads the current pin
values of them. The mask and the return value are 16-bit integers.

=cut

async method read_gpio ( $mask )
{
   await $self->tris_gpio( $mask );

   my $val = unpack "S<", await $self->read_reg( REG_GPIO, 2 );
   return $val & $mask;
}

=head2 tris_gpio

   await $chip->tris_gpio( $mask );

Sets the pins named in the C<$mask> to be inputs ("tristate"). The mask is a
16-bit integer.

=cut

async method tris_gpio ( $mask )
{
   await $self->_cached_maskedwrite_u16( iodir => 0xFFFF, $mask );
}

=head2 set_input_polarity

   await $chip->set_input_polarity( $pol, $mask );

Sets the input polarity of the pins given by C<$mask> to be the values given
in C<$pol>. Pins associated with bits set in C<$pol> will read with an
inverted sense. Both values are 16-bit integers.

=cut

async method set_input_polarity ( $pol, $mask )
{
   await $self->_cached_maskedwrite_u16( ipol => $pol, $mask );
}

=head2 set_input_pullup

   await $chip->set_input_pullup( $pullup, $mask );

Enables or disables the input pullup resistors on the pins given by C<$mask>
as per the values given by C<$pullup>. Both values are 16-bit integers.

=cut

async method set_input_pullup ( $pullup, $mask )
{
   await $self->_cached_maskedwrite_u16( gppu => $pullup, $mask );
}

=head2 as_adapter

   $adapter = $chip->as_adapter;

Returns an instance implementing the L<Device::Chip::Adapter> interface,
allowing access to the GPIO pins via the standard adapter API. See also
L<Device::Chip::MCP23x17::Adapter>.

=cut

method as_adapter
{
   require Device::Chip::MCP23x17::Adapter;
   return Device::Chip::MCP23x17::Adapter->new( chip => $self );
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

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
