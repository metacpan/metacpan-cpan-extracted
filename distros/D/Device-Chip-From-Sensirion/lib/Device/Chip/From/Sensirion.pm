#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

use utf8;

package Device::Chip::From::Sensirion 0.02;
class Device::Chip::From::Sensirion
   :isa(Device::Chip);

use Sublike::Extended 0.29 'method';

use Future::AsyncAwait;

use constant PROTOCOL => "I2C";

=head1 NAME

C<Device::Chip::From::Sensirion> - a collection of chip drivers for F<Sensirion> sensors

=head1 DESCRIPTION

This distribution contains a number of L<Device::Chip> drivers for various
sensor chips manufactured by F<Sensirion>.

It also acts as a base class, providing common functionality for often-used
operations.

=cut

# The CRC algorithm from the data sheet
sub _gen_crc8 ( $bytes )
{
   my $crc = 0xFF;
   foreach my $byte ( unpack "C*", $bytes ) {
      $crc ^= $byte;
      foreach ( 1 .. 8 ) {
         $crc = ( $crc << 1 ) ^ ( ( $crc & 0x80 ) ? 0x31 : 0 );
      }
      $crc &= 0xFF;
   }
   return $crc;
}

sub _pack_with_crc ( $word )
{
   my $bytes = pack "S>", $word;
   return pack "a2 C", $bytes, _gen_crc8( $bytes );
}

=head1 METHODS

=for highlighter language=perl

=cut

async method _cmd ( $cmd,
   :$words_out = undef,
   :$delay = undef,
   :$read = 0,
) {
   my $bytes_out = pack( "S>", $cmd );

   if( $words_out and @$words_out ) {
      $bytes_out .= _pack_with_crc( $_ ) for @$words_out;
   }

   if( !$read ) {
      await $self->protocol->write( $bytes_out );
      return;
   }

   my $protocol = $self->protocol;

   my $bytes_in;
   if( !defined $delay ) {
      $bytes_in = await $protocol->write_then_read( $bytes_out, $read * 3 );
   }
   else {
      await $protocol->write( $bytes_out );
      await $protocol->sleep( $delay );
      $bytes_in = await $protocol->read( $read * 3 );
   }

   # Bytes contains 3x ( 16bit data, 8bit CRC )
   my @dat = unpack( "(a2 C)*", $bytes_in );
   my @words;
   while( @dat ) {
      my $word = shift @dat;
      my $crc = shift @dat;
      die "CRC mismatch on word " . ( scalar @words ) . "\n" if _gen_crc8( $word ) != $crc;
      push @words, unpack "S>", $word;
   }
   return @words;
}

async method _read ( $cmd, $words )
{
   return await $self->_cmd( $cmd, read => $words );
}

# Sensirion chips seem to have a common method for reading their serial number

=head2 get_serial_number

   $bytes = await $chip->get_serial_number;

Returns a 6-byte encoding of the chip's internal serial number.

=cut

async method get_serial_number ()
{
   my @words = await $self->_read( 0x3682, 3 );
   return pack( "(S>)*", @words );
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
