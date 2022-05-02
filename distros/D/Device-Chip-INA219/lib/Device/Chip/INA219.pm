#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2014-2021 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.57;

package Device::Chip::INA219 0.08;
class Device::Chip::INA219
   :isa(Device::Chip::Base::RegisteredI2C 0.10);

use constant REG_DATA_SIZE => 16;

use utf8;

use Carp;
use Future::AsyncAwait;

use Data::Bitfield qw( bitfield boolfield enumfield );

=encoding UTF-8

=head1 NAME

C<Device::Chip::INA219> - chip driver for an F<INA219>

=head1 SYNOPSIS

   use Device::Chip::INA219;
   use Future::AsyncAwait;

   my $chip = Device::Chip::INA219->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   printf "Current bus voltage is %d mV, shunt voltage is %d uV\n",
      await $chip->read_bus_voltage, await $chip->read_shunt_voltage;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Texas Instruments> F<INA219> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

method I2C_options ( %params )
{
   my $addr = delete $params{addr} // 0x40;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 100E3,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

use constant {
   REG_CONFIG  => 0x00, # R/W
   REG_VSHUNT  => 0x01, # R
   REG_VBUS    => 0x02, # R
   REG_POWER   => 0x03, # R
   REG_CURRENT => 0x04, # R
   REG_CALIB   => 0x05, # R/W
};

my @ADCs = qw( 9b 10b 11b 12b . . . .  1 2 4 8 16 32 64 128 );

# We'll use integer encoding and pack/unpack it ourselves because the BADC
# field spans a byte boundary the wrong way
bitfield { format => "integer" }, CONFIG =>
   RST        => boolfield(15),
   BRNG       => enumfield(13, qw( 16V 32V )),
   PG         => enumfield(11, qw( 40mV 80mV 160mV 320mV )),
   BADC       => enumfield( 7, @ADCs),
   SADC       => enumfield( 3, @ADCs),
   MODE_CONT  => boolfield(2),
   MODE_BUS   => boolfield(1),
   MODE_SHUNT => boolfield(0);

=head2 read_config

   $config = await $chip->read_config;

Reads and returns the current chip configuration as a C<HASH> reference.

   RST        => BOOL
   BRNG       => "16V" | "32V"
   PG         => "40mV" | "80mV" | "160mV" | "320mV"
   BADC       => "9b" | "10b" | "11b" | "12b" | 1 | 2 | 4 | 8 | 16 | 32 | 64 | 128
   SADC       => as above
   MODE_CONT  => BOOL
   MODE_BUS   => BOOL
   MODE_SHUNT => BOOL

=cut

has $_config;

async method read_config ()
{
   my $bytes = await $self->cached_read_reg( REG_CONFIG, 1 );

   return $_config = { unpack_CONFIG( unpack "S>", $bytes ) };
}

=head2 change_config

   await $chip->change_config( %config );

Changes the configuration. Any field names not mentioned will be preserved.

=cut

async method change_config ( %changes )
{
   defined $_config or await $self->read_config;

   my %config = ( %{ $_config }, %changes );

   undef $_config; # invalidate the cache

   await $self->write_reg( REG_CONFIG, pack "S>", pack_CONFIG( %config ) );
}

=head2 read_shunt_voltage

   $uv = await $chip->read_shunt_voltage;

Returns the current shunt voltage reading scaled integer in microvolts.

=cut

async method read_shunt_voltage ()
{
   my $vraw = unpack "s>", await $self->read_reg( REG_VSHUNT, 1 );

   # Each $vraw graduation is 10uV
   return $vraw * 10;
}

=head2 read_bus_voltage

   $mv = await $chip->read_bus_voltage;

   ( $mv, $ovf, $cnvr ) = await $chip->read_bus_voltage;

Returns the current bus voltage reading, as a scaled integer in milivolts.

The returned L<Future> also yields the OVF and CNVR flags.

=cut

async method read_bus_voltage ()
{
   my $value = unpack "s>", await $self->read_reg( REG_VBUS, 1 );

   my $ovf  = ( $value & 1<<0 );
   my $cnvr = ( $value & 1<<1 );
   my $vraw = $value >> 3;

   # Each $vraw graduation is 4mV
   return $vraw * 4, $cnvr, $ovf;;
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
