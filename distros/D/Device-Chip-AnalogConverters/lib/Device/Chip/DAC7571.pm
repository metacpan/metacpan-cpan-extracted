#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use 5.026;
use Object::Pad 0.19;

package Device::Chip::DAC7571 0.10;
class Device::Chip::DAC7571
   extends Device::Chip::DAC75xx;

use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=encoding UTF-8

=head1 NAME

C<Device::Chip::DAC7571> - chip driver for F<DAC7571>

=head1 SYNOPSIS

   use Device::Chip::DAC7571;

   my $chip = Device::Chip::DAC7571->new;
   $chip->mount( Device::Chip::Adapter::...->new )->get;

   # Presuming Vcc = 5V
   $chip->write_dac_ratio( 1.23 / 5 )->get;
   print "Output is now set to 1.23V\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<DAC7571> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

This class is derived from L<Device::Chip::DAC75xx>, and inherits the methods
defined there.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

sub I2C_options ( $, %params )
{
   my $addr = delete $params{addr} // 0x4C;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

async method _write ( $code )
{
   await $self->protocol->write( pack "S>", $code );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
