#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2020 -- leonerd@leonerd.org.uk

use v5.26;
use Object::Pad 0.19;

package Device::Chip::BME280 0.02;
class Device::Chip::BME280
   extends Device::Chip::Base::RegisteredI2C;

use Device::Chip::Sensor -declare;

use Data::Bitfield qw( bitfield enumfield boolfield );
use Future::AsyncAwait;

use utf8;

=encoding UTF-8

=head1 NAME

C<Device::Chip::BME280> - chip driver for F<BME280>

=head1 SYNOPSIS

   use Device::Chip::BME280;
   use Future::AsyncAwait;

   my $chip = Device::Chip::BME280->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->change_config(
      OSRS_H => 4,
      OSRS_P => 4,
      OSRS_T => 4,
      MODE   => "NORMAL",
   );

   my ( $pressure, $temperature, $humidity ) = await $chip->read_sensor;

   printf "Temperature=%.2fC  ", $temperature;
   printf "Pressure=%dPa  ", $pressure;
   printf "Humidity=%.2f%%\n", $humidity;

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a F<Bosch>
F<BME280> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method I2C_options
{
   return (
      addr        => 0x76,
      max_bitrate => 400E3,
   );
}

use constant {
   REG_DIG_T1    => 0x88,
   REG_DIG_P1    => 0x8E,
   REG_DIG_H1    => 0xA1,
   REG_ID        => 0xD0,
   REG_RESET     => 0xE0,
   REG_DIG_H2    => 0xE1,
   REG_CTRL_HUM  => 0xF2,
   REG_STATUS    => 0xF3,
   REG_CTRL_MEAS => 0xF4,
   REG_CONFIG    => 0xF5,
   REG_PRESS     => 0xF7, # 24bit
   REG_TEMP      => 0xFA, # 24bit
   REG_HUM       => 0xFD,
};

bitfield { format => "bytes-LE" }, config =>
   # REG_CTRL_HUM
   OSRS_H   => enumfield(     0, qw( SKIP 1 2 4 8 16 16 16 ) ),
   # REG_CTRL_MEAS
   MODE     => enumfield( 2*8+0, qw( SLEEP FORCED FORCED NORMAL ) ),
   OSRS_P   => enumfield( 2*8+2, qw( SKIP 1 2 4 8 16 16 16 ) ),
   OSRS_T   => enumfield( 2*8+5, qw( SKIP 1 2 4 8 16 16 16 ) ),
   # REG_CONFIG
   SPI3W_EN => boolfield( 3*8+0 ),
   FILTER   => enumfield( 3*8+2, qw( OFF 2 4 8 16 16 16 16 ) ),
   T_SB     => enumfield( 3*8+5, qw( 0.5 62.5 125 250 500 1000 10 20 ) );

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_id

   $id = await $chip->read_id

Returns the chip ID.

=cut

async method read_id
{
   return unpack "C", await $self->read_reg( REG_ID, 1 );
}

=head2 read_config

   $config = await $chip->read_config

Returns a C<HASH> reference containing the chip config, using fields named
from the data sheet.

   FILTER   => OFF | 2 | 4 | 8 | 16
   MODE     => SLEEP | FORCED | NORMAL
   OSRS_H   => SKIP | 1 | 2 | 4 | 8 | 16
   OSRS_P   => SKIP | 1 | 2 | 4 | 8 | 16
   OSRS_T   => SKIP | 1 | 2 | 4 | 8 | 16
   SPI3W_EN => 0 | 1
   T_SB     => 0.5 | 10 | 20 | 62.5 | 125 | 250 | 500 | 1000

=cut

async method read_config ()
{
   my $bytes = await $self->cached_read_reg( REG_CTRL_HUM, 4 );

   return { unpack_config( $bytes ) };
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

   my $bytes = pack_config( %$config, %changes );

   # Don't write REG_STATUS
   await $self->cached_write_reg( REG_CTRL_HUM, substr( $bytes, 0, 1 ) );
   await $self->cached_write_reg( REG_CTRL_MEAS, substr( $bytes, 2, 2 ) );
}

async method initialize_sensors ()
{
   await $self->change_config(
      MODE => "NORMAL",
      OSRS_H => 4,
      OSRS_P => 4,
      OSRS_T => 4,
      FILTER => 4,
   );

   # First read after startup contains junk values
   await $self->read_sensor;
}

=head2 read_status

   $status = await $chip->read_status;

=cut

async method read_status ()
{
   my $byte = await $self->read_reg( REG_STATUS, 1 );

   return {
      MEASURING => !!( $byte & (1<<3) ),
      IM_UPDATE => !!( $byte & (1<<0) ),
   };
}

=head2 read_raw

   ( $adc_P, $adc_T, $adc_H ) = await $chip->read_raw

Returns three integers containing the raw ADC reading values from the sensor.

This method is mostly for testing or internal purposes only. For converted
sensor readings in real-world units you want to use L</read_sensor>.

=cut

async method read_raw ()
{
   my ( $bytesP, $bytesT, $bytesH ) = unpack "a3 a3 a2",
      await $self->read_reg( REG_PRESS, 8 );

   return (
      unpack( "L>", "\x00" . $bytesP ) >> 4,
      unpack( "L>", "\x00" . $bytesT ) >> 4,
      unpack( "S>",          $bytesH ),
   );
}

# Compensation formulae directly from BME280 datasheet section 8.1

has $_t_fine;

has @_dig_T;

async method _compensate_temperature ( $adc_T )
{
   @_dig_T or
      @_dig_T = ( undef, unpack "S< s< s<", await $self->read_reg( REG_DIG_T1, 6 ) );

   my $var1 = ($adc_T / 16384 - $_dig_T[1] / 1024) * $_dig_T[2];
   my $var2 = ($adc_T / 131072 - $_dig_T[1] / 8192) ** 2 * $_dig_T[3];

   $_t_fine = int( $var1 + $var2 );
   my $T = ( $var1 + $var2 ) / 5120.0;
   return $T;
}

has @_dig_P;

async method _compensate_pressure ( $adc_P )
{
   @_dig_P or
      @_dig_P = ( undef, unpack "S< s< s< s< s< s< s< s< s<", await $self->read_reg( REG_DIG_P1, 18 ) );

   my $var1 = ($_t_fine / 2) - 64000;
   my $var2 = $var1 * $var1 * $_dig_P[6] / 32768;
   $var2 = $var2 + $var1 * $_dig_P[5] * 2;
   $var2 = ($var2 / 4) + ($_dig_P[4] * 65536);
   $var1 = ($_dig_P[3] * $var1 * $var1 / 524288 + $_dig_P[2] * $var1) / 524288;
   $var1 = (1 + $var1 / 32768) * $_dig_P[1];
   return 0 if $var1 == 0; # avoid exception caused by divide-by-zero
   my $P = 1048576 - $adc_P;
   $P = ($P - ($var2 / 4096)) * 6250 / $var1;
   $var1 = $_dig_P[9] * $P * $P / 2147483648;
   $var2 = $P * $_dig_P[8] / 32768;
   $P = $P + ($var1 + $var2 + $_dig_P[7]) / 16;
   return $P;
}

has @_dig_H;

async method _compensate_humidity ( $adc_H )
{
   unless( @_dig_H ) {
      @_dig_H = (
         undef,
         unpack( "C", await $self->read_reg( REG_DIG_H1, 1 ) ),
         unpack( "s< C ccc c", await $self->read_reg( REG_DIG_H2, 7 ) ),
      );
      # Reshape the two 12bit values
      my ( $b0, $b1, $b2 ) = splice @_dig_H, 4, 3;
      splice @_dig_H, 4, 0,
         ( $b0 << 4 | $b1 & 0x0F ), # H4
         ( $b1 >> 4 | $b2 << 4 );   # H5
   }

   my $var_H = $_t_fine - 76800;
   $var_H = ($adc_H - ($_dig_H[4] * 64.0 + $_dig_H[5] / 16384.0 * $var_H)) *
            ($_dig_H[2] / 65536.0 * (1.0 + $_dig_H[6] / 67108864.0 * $var_H * (1.0 + $_dig_H[3] / 67108864.0 * $var_H)));
   $var_H = $var_H * (1.0 - $_dig_H[1] * $var_H / 524288.0);

   return 0 if $var_H < 0;
   return 100 if $var_H > 100;
   return $var_H;
}

=head2 read_sensor

   ( $pressure, $temperature, $humidity ) = await $chip->read_sensor

Returns the sensor readings appropriately converted into units of Pascals for
pressure, degrees Celcius for temperature, and percentage relative for
humidity.

=cut

async method read_sensor
{
   my ( $adc_P, $adc_T, $adc_H ) = await $self->read_raw;

   # Must do temperature first
   my $T = await $self->_compensate_temperature( $adc_T );

   return (
      await $self->_compensate_pressure( $adc_P ),
      $T,
      await $self->_compensate_humidity( $adc_H ),
   );
}

has $_pending_read_f;

declare_sensor pressure =>
   method => async method {
      $_pending_read_f //= $self->read_raw;
      my ( $rawP, $rawT, undef ) = await $_pending_read_f;
      undef $_pending_read_f;
      $self->_compensate_temperature( $rawT );
      return await $self->_compensate_pressure( $rawP );
   },
   units => "pascals",
   precision => 0;

declare_sensor temperature =>
   method => async method {
      $_pending_read_f //= $self->read_raw;
      my ( undef, $rawT, undef ) = await $_pending_read_f;
      undef $_pending_read_f;
      return await $self->_compensate_temperature( $rawT );
   },
   units => "°C",
   precision => 2;

declare_sensor humidity =>
   method => async method {
      $_pending_read_f //= $self->read_raw;
      my ( undef, $rawT, $rawH ) = await $_pending_read_f;
      undef $_pending_read_f;
      $self->_compensate_temperature( $rawT );
      return await $self->_compensate_humidity( $rawH );
   },
   units => "%RH",
   precision => 2;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
