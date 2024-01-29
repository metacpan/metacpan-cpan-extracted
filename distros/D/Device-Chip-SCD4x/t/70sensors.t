#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter;
use Test::ExpectAndCheck::Future 0.02;  # deferred results

use Future::AsyncAwait;

use Device::Chip::SCD4x;

my $chip = Device::Chip::SCD4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my @sensors = $chip->list_sensors;

is( scalar @sensors, 3, '$chip->list_sensors returns 3 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

# CO2 sensor
{
   my $sensor = $sensors{co2_concentration};

   is( $sensor->units, "ppm", 'CO2 $sensor->units' );

   # Not yet ready - yields undef
   $adapter->expect_write_then_read( "\xE4\xB8", 3 )
      ->will_done( "\x00\x00\x81" );

   is( $sensor->format( scalar await $sensor->read ), undef,
      'Sensor yields undef before chip ready' );

   $adapter->expect_write_then_read( "\xE4\xB8", 3 )
      ->will_done( "\x01\xFF\xD9" );
   $adapter->expect_write_then_read( "\xEC\x05", 9 )
      ->will_done( "\x01\xF4\x33\x66\x67\xA2\x5E\xB9\x3C" );

   is( $sensor->format( scalar await $sensor->read ), "500",
      'CO2 $sensor->read+format' );

   # Not yet ready - holds last value
   $adapter->expect_write_then_read( "\xE4\xB8", 3 )
      ->will_done( "\x00\x00\x81" );

   is( $sensor->format( scalar await $sensor->read ), "500",
      'Sensor yields previous reading when not ready for next' );

   $adapter->check_and_clear( 'CO2 $sensor->read' );
}

# temperature sensor
{
   my $sensor = $sensors{temperature};

   is( $sensor->units, "°C", 'temperature $sensor->units' );

   $adapter->expect_write_then_read( "\xE4\xB8", 3 )
      ->will_done( "\x01\xFF\xD9" );
   $adapter->expect_write_then_read( "\xEC\x05", 9 )
      ->will_done( "\x01\xF4\x33\x66\x67\xA2\x5E\xB9\x3C" );

   is( $sensor->format( scalar await $sensor->read ), "25.00",
      'temperature $sensor->read+format' );

   $adapter->check_and_clear( 'temperature $sensor->read' );
}

# humidity sensor
{
   my $sensor = $sensors{humidity};

   is( $sensor->units, "%RH", 'humidity $sensor->units' );

   $adapter->expect_write_then_read( "\xE4\xB8", 3 )
      ->will_done( "\x01\xFF\xD9" );
   $adapter->expect_write_then_read( "\xEC\x05", 9 )
      ->will_done( "\x01\xF4\x33\x66\x67\xA2\x5E\xB9\x3C" );

   is( $sensor->format( scalar await $sensor->read ), "37.00",
      'humidity $sensor->read+format' );

   $adapter->check_and_clear( 'humidity $sensor->read' );
}

done_testing;
