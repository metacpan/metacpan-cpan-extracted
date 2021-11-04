#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.40;

package Device::Chip::MAX44009 0.03;
class Device::Chip::MAX44009
   extends Device::Chip::Base::RegisteredI2C;

use Device::Chip::Sensor -declare;

use Data::Bitfield qw( bitfield enumfield boolfield );
use Future::AsyncAwait;

=encoding UTF-8

=head1 NAME

C<Device::Chip::MAX44009> - chip driver for F<MAX44009>

=head1 SYNOPSIS

   use Device::Chip::MAX44009;
   use Future::AsyncAwait;

   my $chip = Device::Chip::MAX44009->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->power(1);

   sleep 1; # Wait for one integration cycle

   printf "Current ambient light level is %.2f lux\n",
      scalar await $chip->read_lux;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Maxim Integrated> F<MAX44009> ambient light sensor attached to a computer
via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x4A,
      max_bitrate => 400E3,
   );
}

use constant {
   REG_INTSTATUS => 0x00,
   REG_INTENABLE => 0x01,
   REG_CONFIG    => 0x02,
   REG_LUXH      => 0x03,
   REG_LUXL      => 0x04,
   REG_THRESHU   => 0x05,
   REG_THRESHL   => 0x06,
   REG_THRESHTIM => 0x07,
};

bitfield { format => "bytes-LE" }, CONFIG =>
   CONT   => boolfield(7),
   MANUAL => boolfield(6),
   CDR    => boolfield(3),
   TIM    => enumfield(0, qw( 800 400 200 100 50 25 12.5 6.25 ) );

=head2 read_config

   $config = await $chip->read_config

Returns a C<HASH> reference containing the chip config, using fields named
from the data sheet.

   CONT   => bool
   MANUAL => bool
   CDR    => bool
   TIM    => 800 | 400 | 200 | 100 | 50 | 25 | 12.5 | 6.25

=cut

async method read_config ()
{
   my $bytes = await $self->cached_read_reg( REG_CONFIG, 1 );

   return { unpack_CONFIG( $bytes ) };
}

=head2 change_config

   await $chip->change_config( %changes )

Writes updates to the configuration registers.

Note that these two methods use a cache of configuration bytes to make
subsequent modifications more efficient.

=cut

async method change_config ( %changes )
{
   my $config = await $self->read_config;

   my $bytes = pack_CONFIG( %$config, %changes );

   await $self->cached_write_reg( REG_CONFIG, $bytes );
}

declare_sensor light =>
   method    => "read_lux",
   units     => "lux",
   precision => 2;

=head2 read_lux

   $lux = await $chip->read_lux

Reads the latest light level conversion value and returns the value in Lux.

=cut

async method read_lux ()
{
   # MAX44009 can't do a 2-byte register read.
   # Nor should we just do two 1-byte reads because of nonatomic updates
   # Ugh.
   my $raw = await $self->protocol->txn(async sub {
      my ( $helper ) = @_;
      return unpack "S>", join "",
         await $helper->write_then_read( ( pack "C", REG_LUXH ), 1 ),
         await $helper->write_then_read( ( pack "C", REG_LUXL ), 1 );
   });

   # Unpack the weird 16bit EEEEMMMM....MMMM format
   my $exp = $raw >> 12;
   my $mant = ( ( $raw >> 4 ) & 0xF0 ) | ( $raw & 0x0F );

   my $lux = ( $mant / 16 ) * ( 2 ** $exp );

   return $lux;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
