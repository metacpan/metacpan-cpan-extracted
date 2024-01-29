#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::ADC121Sx 0.16;
class Device::Chip::ADC121Sx
   :isa(Device::Chip);

use Future::AsyncAwait;

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::ADC121Sx> - chip driver for F<ADC121Sx> family

=head1 SYNOPSIS

   use Device::Chip::ADC121Sx;
   use Future::AsyncAwait;

   my $chip = Device::Chip::ADC121Sx->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   printf "The reading is %d\n", await $chip->read_adc;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a chip in
the F<Texas Instruments> F<ADC121Sx> family, such as F<ADC121S021>,
F<ADC121S051> or F<ADC121S101>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options ( $, %params )
{
   return (
      mode        => 2,
      max_bitrate => 20E6,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

# Chip has no config registers
async method read_config () { return {} }
async method change_config (%) { }

=head2 read_adc

   $value = await $chip->read_adc;

Performs a conversion and returns the result as a plain unsigned 12-bit
integer.

=cut

async method read_adc ()
{
   my $buf = await $self->protocol->read( 2 );

   return unpack "S>", $buf;
}

=head2 read_adc_ratio

   $ratio = await $chip->read_adc_ratio;

Performs a conversion and returns the result as a floating-point number
between 0 and 1.

=cut

async method read_adc_ratio ()
{
   # ADC121Sx is 12-bit
   return ( await $self->read_adc ) / 2**12;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
