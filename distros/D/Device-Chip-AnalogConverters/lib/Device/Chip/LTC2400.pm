#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2017-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::LTC2400 0.16;
class Device::Chip::LTC2400
   :isa(Device::Chip);

use Future::AsyncAwait;

use constant PROTOCOL => "SPI";

=head1 NAME

C<Device::Chip::LTC2400> - chip driver for F<LTC2400>

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a
F<Linear Technologies> F<LTC2400> chip attached to a computer via an SPI
adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub SPI_options
{
   return (
      mode        => 0,
      max_bitrate => 2E6,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_adc

   $reading = await $chip->read_adc;

Returns a C<HASH> reference containing the fields obtained after a successful
conversion.

The following values will be stored in the hash:

   EOC   => 0 | 1
   EXR   => 0 | 1
   SIG   => 0 | 1
   VALUE => (a 24bit integer)

If the C<EOC> value is false, then a conversion is still in progress and no
other fields will be provided.

=cut

async method read_adc ()
{
   my $bytes = await $self->protocol->readwrite( "\x00" x 4 );

   my $value = unpack "L>", $bytes;

   if( $value & 1<<30 ) {
      return Future->fail( "Expected dummy bit LOW" );
   }
   if( $value & 1<<31 ) {
      return Future->done( { EOC => 0 } );
   }

   my $sig = ( $value & 1<<29 ) > 0;
   my $exr = ( $value & 1<<28 ) > 0;

   $value &= ( 1<<28 )-1;
   $value >>= 4;

   return {
      EOC   => 1,
      SIG   => $sig,
      EXR   => $exr,
      VALUE => $value,
   };
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
