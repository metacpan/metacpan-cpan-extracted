#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use 5.026;
use Object::Pad 0.19;

package Device::Chip::MAX1166x 0.10;
class Device::Chip::MAX1166x
   extends Device::Chip;

use Future::AsyncAwait;

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::MAX1166x> - chip driver for F<MAX1166x> family

=head1 SYNOPSIS

   use Device::Chip::MAX1166x;

   my $chip = Device::Chip::MAX1166x->new;
   $chip->mount( Device::Chip::Adapter::...->new )->get;

   printf "The reading is %d\n", $chip->read_adc->get;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a chip in
the F<Maxim> F<MAX1166x> family, such as F<MAX11661>, F<MAX11663> or
F<MAX11665>.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options ( $, %params )
{
   return (
      mode        => 2,
      max_bitrate => 8E6,
   );
}

=head1 METHODS

The following methods documented with a trailing call to C<< ->get >> return
L<Future> instances.

=cut

# Chip has no config registers
async method read_config () { return {} }
async method change_config (%) { }

=head2 read_adc

   $value = $chip->read_adc->get

Performs a conversion and returns the result as a plain unsigned 12-bit
integer.

=cut

async method read_adc ()
{
   my $buf = await $self->protocol->read( 2 );

   return unpack "S>", $buf;
}

=head2 read_adc_ratio

   $ratio = $chip->read_adc_ratio->get

Performs a conversion and returns the result as a floating-point number
between 0 and 1.

=cut

async method read_adc_ratio ()
{
   # MAX1166x reads as 14-bit with some trailing zeroes
   # First bit is invalid so must mask it off
   return ( ( await $self->read_adc ) & 0x7FFF ) / 2**14;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
