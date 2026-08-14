#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2026 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

package Device::Chip::BME280 0.08;
class Device::Chip::BME280
   :isa(Device::Chip::BMP280);

use Device::Chip::Sensor 0.27 -declare;

use Future::AsyncAwait;

use utf8;

=encoding UTF-8

=head1 NAME

C<Device::Chip::BME280> - chip driver for F<BME280>

=head1 SYNOPSIS

=for highlighter language=perl

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
F<BME280> attached to a computer via an I²C adapter. As this chip is a
variation of the F<BMP280> which adds a humidity sensor, this module is a
subclass of L<Device::Chip::BMP280>. See that module for documentation on
overall configuration, and access to the temperature and pressure sensors
common to both chips.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=cut

method _has_humidity () { 1 }

use constant WANTED_ID => 0x60;

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

In addition this module inherits all the methods provided by
L<Device::Chip::BMP280>.

=cut

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the chip config, which includes all
the registers provided by C<Device::Chip::BMP280>, and additionally:

   OSRS_H   => SKIP | 1 | 2 | 4 | 8 | 16

=head2 change_config

   await $chip->change_config( %changes );

Writes updates to the configuration registers. Accepts C<OSRS_H> as defined
above.

=cut

# No additional methods as the ones in BMP280 already handle this

=head2 read_raw

   ( $adc_P, $adc_T, $adc_H ) = await $chip->read_raw;

Returns three integers containing the raw ADC reading values from the sensor.

This method is mostly for testing or internal purposes only. For converted
sensor readings in real-world units you want to use L</read_sensor>.

=cut

=head2 read_sensor

   ( $pressure, $temperature, $humidity ) = await $chip->read_sensor;

Returns the sensor readings appropriately converted into units of Pascals for
pressure, degrees Celcius for temperature, and percentage relative for
humidity.

=cut

declare_sensor humidity =>
   method => async method {
      my ( undef, $rawT, $rawH ) = await $self->_next_read;
      $self->_compensate_temperature( $rawT );
      return await $self->_compensate_humidity( $rawH );
   },
   units => "%RH",
   sanity_bounds => [ -1, 101 ], # give it slight headroom beyond the 0-100 range for rounding errors/etc
   precision => 2;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
