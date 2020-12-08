#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2019-2020 -- leonerd@leonerd.org.uk

use 5.026;
use Object::Pad 0.19;

package Device::Chip::BNO055 0.02;
class Device::Chip::BNO055
   extends Device::Chip;

use utf8;

use Carp;
use Future::AsyncAwait;

use Data::Bitfield 0.03 qw( bitfield enumfield );

use constant PROTOCOL => "I2C";

=encoding UTF-8

=cut

=head1 NAME

C<Device::Chip::BNO055> - chip driver for F<BNO055>

=head1 SYNOPSIS

   use Device::Chip::BNO055;
   use Future::AsyncAwait;

   my $chip = Device::Chip::BNO055->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communications to a
F<Bosch> F<BNO055> orientation sensor chip.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

sub I2C_options
{
   return (
      addr        => 0x29,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

# Actual chip hardware uses "paged" registers. We'll fake this for the cache
# by using the 8th bit to store the page number

use constant REGPAGE_1 => 0x80;

use constant {
   REG_CHIP_ID         => 0x00,
   REG_PAGE_ID         => 0x07,
   REG_ACC_DATA_X_LSB  => 0x08,
   REG_MAG_DATA_X_LSB  => 0x0E,
   REG_GYR_DATA_X_LSB  => 0x14,
   REG_EUL_Heading_LSB => 0x1A,
   REG_QUA_Data_w_LSB  => 0x20,
   REG_LIA_Data_X_LSB  => 0x28,
   REG_GRV_Data_X_LSB  => 0x2E,
   REG_UNIT_SEL        => 0x3B,
   REG_OPR_MODE        => 0x3D,

   REG_ACC_Config => REGPAGE_1 | 0x08,
};

my @OPR_MODES = qw(
   CONFIGMODE ACCONLY MAGONLY GYROONLY ACCMAG ACCGYRO MAGGYRO AMG
   IMU COMPASS M4G NDOF_FMC_OFF NDOF
);

bitfield { format => "bytes-LE" }, OPR_MODE =>
   OPR_MODE => enumfield(0, @OPR_MODES);

bitfield { format => "bytes-LE" }, CONFIG =>
   # Page 0
   #
   # REG_UNIT_SEL
   ACC_Unit  => enumfield( 0, qw( m/s² mg )),
   GYR_Unit  => enumfield( 1, qw( dps rps )),
   EUL_Unit  => enumfield( 2, qw( degrees radians )),
   TEMP_Unit => enumfield( 4, qw( Celsius Farenheit )),
   ORI_Android_Windows => enumfield( 7, qw( Windows Android )),

   # REG_OPR_MODE
   OPR_MODE => enumfield(2*8+0, @OPR_MODES),

   # REG_PWR_MODE
   PWR_MODE => enumfield(3*8+0, qw( normal low-power suspend . )),

   # REG_TEMP_SOURCE
   TEMP_Source => enumfield(5*8+0, qw( accelerometer gyroscope . . )),

   # REG_AXIS_MAP_CONFIG
   X_AXIS_MAP => enumfield(6*8+0, qw( X Y Z . )),
   Y_AXIS_MAP => enumfield(6*8+2, qw( X Y Z . )),
   Z_AXIS_MAP => enumfield(6*8+4, qw( X Y Z . )),
   # REG_AXIS_MAP_SIGN
   X_AXIS_SIGN => enumfield(7*8+0, qw( positive negative )),
   Y_AXIS_SIGN => enumfield(7*8+1, qw( positive negative )),
   Z_AXIS_SIGN => enumfield(7*8+2, qw( positive negative )),

   # Page 1
   #
   # REG_ACC_Config
   ACC_Range    => enumfield(8*8+0, qw( 2G 4G 8G 16G )),
   ACC_BW       => enumfield(8*8+2, qw( 7.81Hz 15.63Hz 31.25Hz 62.5Hz 125Hz 250Hz 500Hz 1000Hz )),
   ACC_PWR_Mode => enumfield(8*8+5, qw( normal suspend low-power-1 standby low-power-2 deep-suspend . . )),
   # REG_MAG_Config
   MAG_Data_output_rate => enumfield(9*8+0, qw( 2Hz 6Hz 8Hz 10Hz 15Hz 20Hz 25Hz 30Hz )),
   MAG_OPR_Mode         => enumfield(9*8+3, qw( low-power regular enhanced-regular high-accuracy  )),
   MAG_Power_mode       => enumfield(9*8+6, qw( normal sleep suspend force-mode )),
   # GYR_Config_0
   GYR_Range      => enumfield(10*8+0, qw( 2000dps 1000dps 500dps 250dps 125dps . . . )),
   GYR_Bandwidth  => enumfield(10*8+3, qw( 523Hz 230Hz 116Hz 47Hz 23Hz 12Hz 64Hz 32Hz )),
   # GYR_Config_1
   GYR_Power_Mode => enumfield(11*8+0, qw( normal fast-powerup deep-suspend suspend advanced-powersave . . . )),
   ;

has $_reg_page = 0;
has $_regcache = "";

has $_ACC_Unit;
has $_GYR_Unit;
has $_EUL_Unit;

async method read_reg ( $reg, $len )
{
   my $protocol = $self->protocol;

   my $page = 0 + ( $reg >= REGPAGE_1 ); $reg &= ~REGPAGE_1;

   if( $_reg_page != $page ) {
      await $protocol->write( pack "C C", REG_PAGE_ID, $page );
      $_reg_page = $page;
   }

   return await $protocol->write_then_read( pack( "C", $reg ), $len );
}

async method cached_read_reg ( $reg, $len )
{
   no warnings 'numeric'; # quiet the warning about negative repeat count

   if( length $_regcache >= $reg + $len ) {
      return substr( $_regcache, $reg, $len );
   }

   my $bytes = await $self->read_reg( $reg, $len );
   $_regcache .= "\0" x ( $reg + $len - length $_regcache );
   substr( $_regcache, $reg, $len ) = $bytes;

   return $bytes;
}

async method write_reg ( $reg, $bytes )
{
   my $protocol = $self->protocol;

   my $page = 0 + ( $reg >= REGPAGE_1 ); $reg &= ~REGPAGE_1;

   if( $_reg_page != $page ) {
      await $protocol->write( pack "C C", REG_PAGE_ID, $page );
      $_reg_page = $page;
   }

   return await $protocol->write( pack "C a*", $reg, $bytes );
}

async method cached_write_reg ( $reg, $bytes )
{
   no warnings 'numeric'; # quiet the warning about negative repeat count

   # Trim common prefix/suffix
   while( length $bytes and substr( $bytes, 0, 1 ) eq substr( $_regcache, $reg, 1 ) ) {
      $bytes =~ s/^.//s;
      $reg++;
   }

   my $len = length $bytes;
   while( $len and substr( $bytes, $len - 1, 1 ) eq substr( $_regcache, $reg + $len - 1, 1 ) ) {
      $bytes =~ s/.$//s;
      $len--;
   }

   return unless $len;

   await $self->write_reg( $reg, $bytes );

   $_regcache .= "\0" x ( $reg + $len - length $_regcache );
   substr( $_regcache, $reg, $len ) = $bytes;
}

=head2 read_ids

   $ids = await $chip->read_ids;

Returns an 8-character string composed of the four ID registers. For a
C<BNO055> chip this should be the string

   "A0FB320F"

=cut

async method read_ids ()
{
   return uc unpack "H*", await $self->read_reg( REG_CHIP_ID, 4 );
}

=head2 read_config

   $config = await $chip->read_config;

Returns the current chip configuration.

=cut

async method read_config ()
{
   return {
      unpack_CONFIG( join "", await Future->needs_all(
         $self->cached_read_reg( REG_UNIT_SEL, 8 ),
         $self->cached_read_reg( REG_ACC_Config, 4 ),
      ) ),
   };
}

=head2 change_config

   await $chip->change_config( %changes );

Changes the configuration. Any field names not mentioned will be preserved at
their existing values.

This method can only be used while the chip is in config mode, and cannot
itself be used to set C<OPR_MODE>. For that, use L</set_opr_mode>.

=cut

async method change_config ( %changes )
{
   $changes{OPR_MODE} and
      croak "->change_config cannot change OPR_MODE; use ->set_opr_mode\n";

   my $config = await $self->read_config;

   $config->{OPR_MODE} eq "CONFIGMODE" or
      croak "Can only ->change_config when in CONFIGMODE";

   $config->{$_} = $changes{$_} for keys %changes;

   my ( $page0, $page1 ) = unpack "a8 a4", pack_CONFIG( %$config );

   await Future->needs_all(
      $self->cached_write_reg( REG_UNIT_SEL, $page0 ),
      $self->cached_write_reg( REG_ACC_Config, $page1 ),
   );
}

=head2 set_opr_mode

   await $chip->set_opr_mode( $mode );

Sets the C<OPR_MODE> register.

=cut

async method set_opr_mode ( $mode )
{
   # TODO: Only allow state transitions when one of old or new mode is CONFIGMODE

   await $self->cached_write_reg( REG_OPR_MODE, pack_OPR_MODE( OPR_MODE => $mode ) );
}

=head2 read_accelerometer_raw

   ( $x, $y, $z ) = await $chip->read_accelerometer_raw;

Returns the most recent accelerometer readings in raw 16bit signed integers

=cut

async method read_accelerometer_raw ()
{
   return unpack "s< s< s<", await $self->read_reg( REG_ACC_DATA_X_LSB, 6 );
}

=head2 read_accelerometer

   ( $x, $y, $z ) = await $chip->read_accelerometer;

Returns the most recent accelerometer readings in converted units, either
C<m/s²> or C<G> depending on the chip's C<ACC_Unit> configuration.

=cut

async method read_accelerometer ()
{
   my $units = $_ACC_Unit //= ( await $self->read_config )->{ACC_Unit};

   if( $units eq "mg" ) {
      return map { $_ / 1000 } await $self->read_accelerometer_raw;
   }
   elsif( $units eq "m/s²" ) {
      return map { $_ / 100 } await $self->read_accelerometer_raw;
   }
}

=head2 read_magnetometer_raw

   ( $x, $y, $z ) = await $chip->read_magnetometer_raw;

Returns the most recent magnetometer readings in raw 16bit signed integers

=cut

async method read_magnetometer_raw ()
{
   return unpack "s< s< s<", await $self->read_reg( REG_MAG_DATA_X_LSB, 6 );
}

=head2 read_magnetometer

   ( $x, $y, $z ) = await $chip->read_magnetometer;

Returns the most recent magnetometer readings in converted units of C<µT>.

=cut

async method read_magnetometer ()
{
   return map { $_ / 16 } await $self->read_magnetometer_raw;
}

=head2 read_gyroscope_raw

   ( $x, $y, $z ) = await $chip->read_gyroscope_raw;

Returns the most recent gyroscope readings in raw 16bit signed integers

=cut

async method read_gyroscope_raw ()
{
   return unpack "s< s< s<", await $self->read_reg( REG_GYR_DATA_X_LSB, 6 );
}

=head2 read_gyroscope

   ( $x, $y, $z ) = await $chip->read_gyroscope;

Returns the most recent gyroscope readings in converted units, either
C<dps> or C<rps> depending on the chip's C<GYR_Unit> configuration.

=cut

async method read_gyroscope ()
{
   my $units = $_GYR_Unit //= ( await $self->read_config )->{GYR_Unit};

   if( $units eq "dps" ) {
      return map { $_ / 16 } await $self->read_gyroscope_raw;
   }
   elsif( $units eq "rps" ) {
      return map { $_ / 900 } await $self->read_gyroscope_raw;
   }
}

=head2 read_euler_angles

   ( $heading, $roll, $pitch ) = await $chip->read_euler_angles;

Returns the most recent Euler angle fusion readings in converted units, either
degrees or radians depending on the chip's C<EUL_units> configuration.

=cut

async method read_euler_angles ()
{
   my $units = $_EUL_Unit //= ( await $self->read_config )->{EUL_Unit};

   my ( $heading, $roll, $pitch ) = unpack "s< s< s<", await $self->read_reg( REG_EUL_Heading_LSB, 6 );

   if( $units eq "degrees" ) {
      return map { $_ / 16 } ( $heading, $roll, $pitch );
   }
   elsif( $units eq "radians" ) {
      return map { $_ / 900 } ( $heading, $roll, $pitch );
   }
}

=head2 read_quarternion

   ( $w, $x, $y, $z ) = await $chip->read_quarternion;

Returns the most recent quarternion fusion readings in converted units as
scaled numbers between -1 and 1.

=cut

async method read_quarternion ()
{
   my ( $w, $x, $y, $z ) = unpack "s< s< s< s<", await $self->read_reg( REG_QUA_Data_w_LSB, 8 );

   return map { $_ / 2**14 } ( $w, $x, $y, $z );
}

=head2 read_linear_acceleration

   ( $x, $y, $z ) = await $chip->read_linear_acceleration;

Returns the most recent linear acceleration fusion readings in converted
units, either C<m/s²> or C<G> depending on the chip's C<ACC_units>
configuration.

=cut

async method read_linear_acceleration ()
{
   my $units = $_ACC_Unit //= ( await $self->read_config )->{ACC_Unit};

   my ( $x, $y, $z ) = unpack "s< s< s<", await $self->read_reg( REG_LIA_Data_X_LSB, 6 );

   if( $units eq "mg" ) {
      return map { $_ / 1000 } ( $x, $y, $z );
   }
   elsif( $units eq "m/s²" ) {
      return map { $_ / 100 } ( $x, $y, $z );
   }
}

=head2 read_linear_acceleration

   ( $x, $y, $z ) = await $chip->read_linear_acceleration;

Returns the most recent gravity fusion readings in converted units, either
C<m/s²> or C<G> depending on the chip's C<ACC_units> configuration.

=cut

async method read_gravity ()
{
   my $units = $_ACC_Unit //= ( await $self->read_config )->{ACC_Unit};

   my ( $x, $y, $z ) = unpack "s< s< s<", await $self->read_reg( REG_GRV_Data_X_LSB, 6 );

   if( $units eq "mg" ) {
      return map { $_ / 1000 } ( $x, $y, $z );
   }
   elsif( $units eq "m/s²" ) {
      return map { $_ / 100 } ( $x, $y, $z );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
