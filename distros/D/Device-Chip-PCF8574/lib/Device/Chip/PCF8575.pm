#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::PCF8575 0.05;
class Device::Chip::PCF8575
   :isa(Device::Chip::PCF857x);

=encoding UTF-8

=head1 NAME

C<Device::Chip::PCF8575> - chip driver for a F<PCF8575> or F<PCA8575>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<NXP> or F<Texas Instruments> F<PCF8575> attached to a computer via an I²C
adapter. Due to hardware similarity this can also drive a F<PCA8575>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 write

   await $chip->write( $val );

Sets the value of the GPIO pins, as a 16-bit integer.

Pins set low will sink current suitable for signalling or driving an LED. Pins
set high will source current via a weak current-source to act as a pull-up for
an active-low input signal, such as a button.

=cut

=head2 read

   $val = await $chip->read;

Reads the current logic levels on the GPIO pins, returned as a 16-bit
integer. Pins of interest as inputs should have previously been set to high
level using the L</write> method.

=cut

use constant PACKFMT => "S<";
use constant READLEN => 2;

=head2 as_adapter

   $adapter = $chip->as_adapter

Returns a new object implementing the L<Device::Chip::Adapter> interface which
allows access to the GPIO pins of the chip as if it was a GPIO protocol
adapter. The returned instance supports the following methods:

   $protocol = await $adapter->make_protocol( 'GPIO' )

   $protocol->list_gpios
   await $protocol->write_gpios
   await $protocol->read_gpios
   await $protocol->tris_gpios

=cut

use constant DEFMASK => 0xFFFF;
use constant GPIOBITS => {
   ( map { +"P0$_", (     1 << $_ ) } 0 .. 7 ),
   ( map { +"P1$_", ( 0x100 << $_ ) } 0 .. 7 )
};

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
