#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

use utf8;

package Device::Chip::SCD4x 0.02;
class Device::Chip::SCD4x
   :isa(Device::Chip::From::Sensirion);

use Future::AsyncAwait;

use Device::Chip::Sensor 0.23 -declare;

=encoding UTF-8

=head1 NAME

C<Device::Chip::SCD4x> - chip driver for F<SCD40> and F<SCD41>

=head1 SYNOPSIS

=for highlighter language=perl

   use Device::Chip::SCD4x;
   use Future::AsyncAwait;

   my $chip = Device::Chip::SCD4x->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   await $chip->start_periodic_measurement;

   while(1) {
      await Future::IO->sleep(1);

      my ( $co2, $temp, $humid ) = await $chip->maybe_read_measurement
         or next;

      printf "CO2 concentration=%dppm  ", $co2;
      printf "Temperature=%.2fC  ", $temp;
      printf "Humidity=%.2f%%\n", $hum;
   }

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Sensirion> F<SCD40> or F<SCD41> attached to a computer via an I²C adapter.

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
   my $addr = delete $params{addr} // 0x62;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the compensation values from chip
config.

=for highlighter

   temperature_offset # in degrees C
   sensor_altitude    # in metres
   ambient_pressure   # in hPa

=cut

field %config_f;

async method read_config
{
   await Future->needs_all(
      $config_f{temperature_offset} //= $self->_read( 0x2318, 1 ),
      $config_f{sensor_altitude}    //= $self->_read( 0x2322, 1 ),
      $config_f{ambient_pressure}   //= $self->_read( 0xe000, 1 ),
   );

   return {
      temperature_offset => ( $config_f{temperature_offset}->result * 175 ) / 0xFFFF,
      sensor_altitude    => $config_f{sensor_altitude}->result,
      ambient_pressure   => $config_f{ambient_pressure}->result * 100,
   };
}

=head2 start_periodic_measurement

=for highlighter language=perl

   await $chip->start_periodic_measurement;

Starts periodic measurement mode.

=cut

async method start_periodic_measurement ()
{
   await $self->_cmd( 0x21b1 );
}

=head2 read_measurement

   ( $co2concentration, $temperature, $humidity ) = await $chip->read_measurement();

Returns the latest sensor reading values. Returns a 3-element list, containing
the CO₂ concentration in PPM, temperature in degrees C, and humidity in %RH.

=cut

async method read_measurement ()
{
   my @words = await $self->_read( 0xec05, 3 );

   return (
      # CO2
      $words[0],
      # Temperature
      -45 + 175 * ( $words[1] / 0xFFFF ),
      # Humidity
      100 * ( $words[2] / 0xFFFF ),
   );
}

=head2 maybe_read_measurement

   ( $co2concentration, $temperature, $humidity ) = await $chip->maybe_read_measurement();

If the sensor has a new measurement ready, returns it. Otherwise, returns the
last successful measurement reading. After initial startup, this will return
an empty list before the first reading is available.

=cut

field @last_measurement;
async method maybe_read_measurement ()
{
   # Ready if the lowest 11 bits are nonzero
   my $ready = 0x07FF & await $self->_read( 0xe4b8, 1 );
   $ready or return @last_measurement;

   return @last_measurement = await $self->read_measurement;
}

async method initialize_sensors ()
{
   # Startup delay
   await Future::IO->sleep( 0.05 );

   await $self->start_periodic_measurement;
}

field $_pending_next_read_f;
method _next_read
{
   return $_pending_next_read_f //=
      $self->maybe_read_measurement->on_ready(sub { undef $_pending_next_read_f });
}

declare_sensor co2_concentration =>
   method => async method {
      return ( await $self->_next_read )[0];
   },
   units => "ppm",
   sanity_bounds => [ 300, 8000 ],
   precision => 0;

declare_sensor temperature =>
   method => async method {
      return ( await $self->_next_read )[1];
   },
   units => "°C",
   sanity_bounds => [ -50, 80 ],
   precision => 2;

declare_sensor humidity =>
   method => async method {
      return ( await $self->_next_read )[2];
   },
   units => "%RH",
   sanity_bounds => [ -1, 101 ], # give it slight headroom beyond the 0-100 range for rounding errors/etc
   precision => 2;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
