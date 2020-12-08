#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2018-2020 -- leonerd@leonerd.org.uk

use 5.026;
use Object::Pad 0.19;

package Device::Chip::DAC75xx 0.11;
class Device::Chip::DAC75xx
   extends Device::Chip;

use Carp;
use Future::AsyncAwait;

=encoding UTF-8

=head1 NAME

C<Device::Chip::DAC75xx> - common chip driver for F<DAC75xx>-family DACs

=head1 DESCRIPTION

This L<Device::Chip> subclass provides a base class for specific chip drivers
for chips in the F<Texas Instruments> DAC 75xx family.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

my %NAME_TO_POWERDOWN = (
   normal => 0,
   "1k"   => 1,
   "100k" => 2,
   "hiZ"  => 3,
);

# Chip has no config registers
async method read_config () { return {} }
async method change_config (%) { }

=head2 write_dac

   await $chip->write_dac( $dac, $powerdown );

Writes a new value for the DAC output and powerdown state.

C<$powerdown> is optional and will default to C<normal> if not provided. Must
be one of the following four values

   normal 1k 100k hiZ

=cut

async method write_dac ( $dac, $powerdown = undef )
{
   $dac &= 0x0FFF;

   my $pd = 0;
   $pd = $NAME_TO_POWERDOWN{$powerdown} // croak "Unrecognised powerdown state '$powerdown'"
      if defined $powerdown;

   await $self->_write( $pd << 12 | $dac );
}

=head2 write_dac_ratio

   await $chip->write_dac_ratio( $ratio );

Writes a new value for the DAC output as a scaled ratio between 0.0 and 1.0.

=cut

async method write_dac_ratio ( $ratio )
{
   await $self->write_dac( $ratio * 2**12 );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
