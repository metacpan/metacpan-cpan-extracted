#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2023 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::OPT3001 0.03;
class Device::Chip::OPT3001
   :isa(Device::Chip::Base::RegisteredI2C);

use Device::Chip::Sensor -declare;

use Data::Bitfield qw( bitfield enumfield boolfield intfield );
use Future::AsyncAwait;
use Future::IO;

use constant REG_DATA_SIZE => 16;

=encoding UTF-8

=head1 NAME

C<Device::Chip::OPT3001> - chip driver for F<OPT3001>

=head1 SYNOPSIS

   use Device::Chip::OPT3001;
   use Future::AsyncAwait;

   my $chip = Device::Chip::OPT3001->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->power(1);

   sleep 1; # Wait for one integration cycle

   printf "Current ambient light level is %.2f lux\n",
      scalar await $chip->read_lux;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<OPT3001> ambient light sensor attached to a computer
via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x44,
      max_bitrate => 400E3,
   );
}

use constant {
   REG_RESULT => 0x00,
   REG_CONFIG => 0x01,
   REG_LIML   => 0x02,
   REG_LIMH   => 0x03,

   REG_MANUF_ID => 0x7E,
   REG_PROD_ID  => 0x7F,
};

bitfield { format => "integer" }, CONFIG =>
   RN  => intfield(12, 4),
   CT  => enumfield(11, qw( 100 800 )),
   M   => enumfield(9, qw( shutdown single cont cont )),
   OVF => boolfield(8),
   CRF => boolfield(7),
   FH  => boolfield(6),
   FL  => boolfield(5),
   L   => boolfield(4),
   POL => enumfield(3, qw( active-low active-high )),
   ME  => boolfield(2),
   FC  => enumfield(0, qw( 1 2 4 8 ));

=head2 read_config

   $config = await $chip->read_config

Returns a C<HASH> reference containing the chip config, using fields named
from the data sheet.

   RN  => 0 .. 15
   CT  => 100 | 800
   M   => "shutdown" | "single" | "cont"
   OVF => bool
   CRF => bool
   FH  => bool
   FL  => bool
   L   => bool
   POL => "active-low" | "active-high"
   ME  => bool
   FC  => 1 | 2 | 4 | 8

=cut

async method read_config ()
{
   my $bytes = await $self->cached_read_reg( REG_CONFIG, 1 );

   return { unpack_CONFIG( unpack "S>", $bytes ) };
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

   my $bytes = pack "S>", pack_CONFIG( %$config, %changes );

   await $self->cached_write_reg( REG_CONFIG, $bytes );
}

async method initialize_sensors ()
{
   await $self->change_config( M => "cont" );

   # Give it a moment or two to start up
   await Future::IO->sleep( 0.900 );
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
   my $raw = unpack "S>", await $self->read_reg( REG_RESULT, 1 );

   # Unpack the 4.12 floating point format
   my $exp = ( $raw >> 12 );
   my $lux = ( $raw & 0x0FFF ) * ( 2 ** $exp ) * 0.01;

   return $lux;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
