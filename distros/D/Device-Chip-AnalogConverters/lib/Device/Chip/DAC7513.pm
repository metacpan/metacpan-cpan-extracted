#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::DAC7513 0.16;
class Device::Chip::DAC7513
   :isa(Device::Chip::DAC75xx);

use Future::AsyncAwait;

use constant PROTOCOL => "SPI";

=encoding UTF-8

=head1 NAME

C<Device::Chip::DAC7513> - chip driver for F<DAC7513>

=head1 SYNOPSIS

   use Device::Chip::DAC7513;
   use Future::AsyncAwait;

   my $chip = Device::Chip::DAC7513->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   # Presuming Vcc = 5V
   await $chip->write_dac_ratio( 1.23 / 5 );
   print "Output is now set to 1.23V\n";

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<DAC7513> attached to a computer via an SPI adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

This class is derived from L<Device::Chip::DAC75xx>, and inherits the methods
defined there.

=cut

sub SPI_options ( $, %params )
{
   return (
      max_bitrate => 30E6,
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
