#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2024 -- leonerd@leonerd.org.uk

use v5.26;
use warnings;
use Object::Pad 0.800;

use utf8;

package Device::Chip::SHT4x 0.03;
class Device::Chip::SHT4x
   :isa(Device::Chip::From::Sensirion);

use Carp;

use Future::AsyncAwait;

use List::Util qw( first );

use Device::Chip::Sensor 0.23 -declare;

=encoding UTF-8

=head1 NAME

C<Device::Chip::SHT4x> - chip driver for F<SHT40> and F<SHT41>

=head1 SYNOPSIS

=for highlighter language=perl

   use Device::Chip::SHT4x;
   use Future::AsyncAwait;

   my $chip = Device::Chip::SHT4x->new;
   await $chip->mount( Device::Chip::Adapter::...->new );

   while(1) {
      await Future::IO->sleep(1);

      my ( $temp, $humid ) = await $chip->read_measurement;

      printf "Temperature=%.2fC  ", $temp;
      printf "Humidity=%.2f%%\n", $hum;
   }

=head1 DESCRIPTION

This L<Device::Chip> subclass provides specific communication to a
F<Sensirion> F<SHT40> or F<SHT41> attached to a computer via an I²C adapter.

The reader is presumed to be familiar with the general operation of this chip;
the documentation here will not attempt to explain or define chip-specific
concepts or features, only the use of this module to access them.

=head2 Heater Operation

By default, the heater ability of the chip is not used by the
L</read_measurement> method.

If enabled by the C<heater_power> and C<heater_duration> settings, then the
method might enable the heater at each measurement.

If C<heater_interval> is not defined, then the heater will be used for
I<every> call to L</read_measurement>, and thus the returned readings will
have been performed with that in effect. This will cause the sensor to report
the temperature higher than, and humidity lower than, the actual ambient
environment.

If C<heater_interval> is defined, then the heater will only be activated each
call if it hasn't been activated within that time before. Any measurement made
within C<heater_cooldown> seconds of the most recent heater operation will not
report the actual sensor values, but instead will report the (cached) readings
from the most recent non-heater measurement cycle.

When using the periodic heater, the heater will only activate each cycle if
the previous reading was within both limits set by C<heater_max_temperature>
and C<heater_min_humidity>. If either limit is exceeded then the heater will
not be activated.

=cut

=head1 MOUNT PARAMETERS

=head2 addr

The I²C address of the device. Can be specified in decimal, octal or hex with
leading C<0> or C<0x> prefixes.

=cut

method I2C_options ( %params )
{
   my $addr = delete $params{addr} // 0x44;
   $addr = oct $addr if $addr =~ m/^0/;

   return (
      addr        => $addr,
      max_bitrate => 400E3,
   );
}

# SHT4x uses only 8bit commands
use constant PACK_FORMAT_CMD => "C";

=head1 METHODS

The following methods documented in an C<await> expression return L<Future>
instances.

=cut

use constant CMD_READ_HIGH_NO_HEATER => 0xFD;
# command to read normally
field $read_cmd = CMD_READ_HIGH_NO_HEATER;

field $heater_interval;
field $heater_cooldown = 5;
# Don't run the heater past these values
field $heater_max_temperature = 65;
field $heater_min_humidity    = 80;

my %CMD_CONFIG = (
   # cmd => [ precision, heater power, heater duration ],
   0xE0,    [ "low",     "off",        "off"  ],
   0xF6,    [ "medium",  "off",        "off"  ],
   0xFD,    [ "high",    "off",        "off"  ],
   0x15,    [ "high",    "20mW",       "0.1s" ],
   0x1E,    [ "high",    "20mW",       "1s"   ],
   0x24,    [ "high",    "110mW",      "0.1s" ],
   0x2F,    [ "high",    "110mW",      "1s"   ],
   0x32,    [ "high",    "200mW",      "0.1s" ],
   0x39,    [ "high",    "200mW",      "1s"   ],
);

=head2 read_config

   $config = await $chip->read_config;

Returns a C<HASH> reference containing the configuration.

While the chip itself does not have any configuration registers, this driver
module stores the following fields directly to influence which measurement
commands it uses to request readings from the chip.

=for highlighter

   precision       => low | medium | high
   heater_power    => off | 20mW | 110mW | 200mW
   heater_duration => off | 0.1s | 1s
   heater_interval => undef | NUM
   heater_cooldown => undef | NUM
   heater_max_temperature => NUM
   heater_min_humidity    => NUM

The module defaults to C<high> precision, heater off.

Due to the way the F<SHT4x> works, the precision field is ignored if the
heater is enabled; measurements are always high-precision.

The various C<heater_*> settings are described above, under
L</Heater Operation>. The C<heater_cooldown> setting defaults to 5 seconds,
C<heater_max_temperature> to 65 C, and C<heater_min_humidity> to 80 %RH.

=cut

async method read_config ()
{
   my ( $precision, $heater_power, $heater_duration ) = @{ $CMD_CONFIG{$read_cmd} };

   return {
      precision       => $precision,
      heater_power    => $heater_power,
      heater_duration => $heater_duration,
      heater_interval => $heater_interval,
      heater_cooldown => $heater_cooldown,
      heater_max_temperature => $heater_max_temperature,
      heater_min_humidity    => $heater_min_humidity,
   };
}

=head2 change_config

=for highlighter language=perl

   await $chip->change_config( %changes );

Writes updates to the stored configuration settings, which will take effect
in the next call to the measurement method.

=cut

async method change_config ( %changes )
{
   my %config = ( %{ await $self->read_config }, %changes );

   my $new_precision = delete $config{precision};
   grep { $new_precision eq $_ } qw( high medium low ) or
      croak "Unrecognised value '$new_precision' for 'precision'";

   my $new_power    = delete $config{heater_power}    // "off";
   grep { $new_power eq $_ } qw( off 20mW 110mW 200mW ) or
      croak "Unrecognised value '$new_power' for 'heater_power'";

   my $new_duration = delete $config{heater_duration} // "off";
   grep { $new_duration eq $_ } qw( off 0.1s 1s ) or
      croak "Unrecognised value '$new_duration' for 'heater_duration'";

   $heater_interval = delete $config{heater_interval};

   $heater_cooldown = delete $config{heater_cooldown};

   $heater_max_temperature = delete $config{heater_max_temperature};

   $heater_min_humidity    = delete $config{heater_min_humidity};

   keys %config and
      croak "Unrecognised configuration keys: " . join( ", ", sort keys %config );

   if( $new_power eq "off" ) {
      $new_duration = "off";
   }
   else {
      # with heater on, precision must be high
      $new_precision = "high";
   }

   my $new_cmd = first {
      my $conf = $CMD_CONFIG{$_};
      $conf->[0] eq $new_precision &&
         $conf->[1] eq $new_power &&
         $conf->[2] eq $new_duration
   } keys %CMD_CONFIG;

   defined $new_cmd or
      croak "Unable to find a read command for prec=$new_precision pow=$new_power dur=$new_duration";

   if( $new_power eq "off" ) {
      $read_cmd = $new_cmd;
      $heater_interval = undef;
   }
   else {
      $read_cmd = $new_cmd;
   }
}

async method get_serial_number ()
{
   my @words = await $self->_read( 0x89, 2 );
   return pack( "(S>)*", @words );
}

=head2 read_measurement

   ( $temperature, $humidity ) = await $chip->read_measurement();

Performs a measurement and returns the sensor reading values. Returns a
2-element list, containing temperature in degrees C, and humidity in %RH.

=cut

my %DELAY_FOR_CMD = (
   # cmd, delay
   0x15, 0.110, # high, 20mW, 0.1s
   0x1E, 1.010, # high, 20mW, 1s
   0x24, 0.110, # high, 110mW, 0.1s
   0x2F, 1.010, # high, 110mW, 1s
   0x32, 0.110, # high, 200mW, 0.1s
   0x39, 1.010, # high, 200mW, 1s
   0xE0, 0.002, # high, off
   0xF6, 0.005, # medium, off
   0xFD, 0.010, # low, off
);

field $last_read_with_heater;
field $last_temperature;
field $last_humidity;

method should_use_heater ( $now )
{
   return 0 if $now < $last_read_with_heater + $heater_interval;

   return 0 if $last_temperature > $heater_max_temperature;
   return 0 if $last_humidity    < $heater_min_humidity;

   return 1;
}

async method read_measurement ()
{
   my $use_heater;
   my $use_last_cache;

   if( defined $last_temperature and defined $heater_interval ) {
      my $now = time();
      $last_read_with_heater //= 0;
      if( $self->should_use_heater( $now ) ) {
         $use_heater = 1;
         $last_read_with_heater = $now;
      }

      $use_last_cache = defined $last_temperature &&
         defined $heater_cooldown &&
         $now - $last_read_with_heater < $heater_cooldown;
   }

   my $cmd = $read_cmd;
   if( defined $heater_interval and !$use_heater ) {
      $cmd = CMD_READ_HIGH_NO_HEATER;

      return ( $last_temperature, $last_humidity ) if $use_last_cache;
   }

   my @words = await $self->_cmd( $cmd,
      delay => $DELAY_FOR_CMD{$cmd},
      read  => 2,
   );

   return ( $last_temperature, $last_humidity ) if $use_last_cache;

   return (
      # Temperature
      $last_temperature = -45 + 175 * ( $words[0] / 0xFFFF ),
      # Humidity
      #   Note: different conversion formula as per SCD4x
      $last_humidity = -6 + 125 * ( $words[1] / 0xFFFF ),
   );
}

field $_pending_next_read_f;
method _next_read
{
   return $_pending_next_read_f //=
      $self->read_measurement->on_ready(sub { undef $_pending_next_read_f });
}

declare_sensor temperature =>
   method => async method {
      return ( await $self->_next_read )[0];
   },
   units => "°C",
   sanity_bounds => [ -50, 80 ],
   precision => 2;

declare_sensor humidity =>
   method => async method {
      return ( await $self->_next_read )[1];
   },
   units => "%RH",
   sanity_bounds => [ -1, 101 ], # give it slight headroom beyond the 0-100 range for rounding errors/etc
   precision => 2;

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
