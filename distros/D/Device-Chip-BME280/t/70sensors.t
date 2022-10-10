#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test::More;
use Test::Device::Chip::Adapter;
use Test::ExpectAndCheck::Future 0.02;  # deferred results

use Future::AsyncAwait;

use Device::Chip::BME280;

my $chip = Device::Chip::BME280->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# precache config
{
   $adapter->expect_write_then_read( "\xF2", 4 )
      ->will_done( "\x00\x00\x00\x00" );

   await $chip->read_config;
}

my @sensors = $chip->list_sensors;

is( scalar @sensors, 3, '$chip->list_sensors returns 2 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

# temperature sensor
{
   my $sensor = $sensors{temperature};

   is( $sensor->units, "°C", 'temperature $sensor->units' );

   # sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );
   # DIG_T compensation
   $adapter->expect_write_then_read( "\x88", 6 )
      ->will_done( "\x1C\x6F\x27\x69\x32\x00" );

   is( $sensor->format( scalar await $sensor->read ), "21.81",
      'temperature $sensor->read+format' );

   $adapter->check_and_clear( 'temperature $sensor->read' );
}

# pressure sensor
{
   my $sensor = $sensors{pressure};

   is( $sensor->units, "pascals", 'pressure $sensor->units' );

   # sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );
   # DIG_P compensation
   $adapter->expect_write_then_read( "\x8E", 18 )
      ->will_done( "\xAA\x8E\x03\xD7\xD0\x0B\x21\x21\x83\xFF\xF9\xFF\xAC\x26\x0A\xD8\xBD\x10" );

   is( $sensor->format( scalar await $sensor->read ), "97033",
      'pressure $sensor->read+format' );

   $adapter->check_and_clear( 'pressure $sensor->read' );
}

# humidity sensor
{
   my $sensor = $sensors{humidity};

   is( $sensor->units, "%RH", 'humidity $sensor->units' );

   # sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );
   # DIG_H compensation is in two pieces
   $adapter->expect_write_then_read( "\xA1", 1 )
      ->will_done( "\x4B" );
   $adapter->expect_write_then_read( "\xE1", 7 )
      ->will_done( "\x78\x01\x00\x11\x2E\x03\x1E" );

   is( $sensor->format( scalar await $sensor->read ), "42.75",
      'humidity $sensor->read+format' );

   $adapter->check_and_clear( 'humidity $sensor->read' );
}

# sensors concurrently
{
   # Expect just a single read of sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );

   my $fT = $sensors{temperature}->read;
   my $fP = $sensors{pressure}->read;
   my $fH = $sensors{humidity}->read;

   is( int await $fT, 21,    'temperature value' );
   is( int await $fP, 97032, 'pressure value' );
   is( int await $fH, 42,    'humidity value' );
}

# failures are not cached
{
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_fail( "I2C read timeout\n" );

   my $fT = $sensors{temperature}->read;
   my $fP = $sensors{pressure}->read;
   my $fH = $sensors{humidity}->read;

   is( $fT->failure, "I2C read timeout\n", 'temperature failed' );
   is( $fP->failure, "I2C read timeout\n", 'pressure failed' );
   is( $fH->failure, "I2C read timeout\n", 'humidity failed' );

   # Second attempt should succeed
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\xCF\x00\x80\x20\x00\x63\xC0" );

   $fT = $sensors{temperature}->read;
   $fP = $sensors{pressure}->read;
   $fH = $sensors{humidity}->read;

   is( int await $fT, 22,    'temperature value' );
   is( int await $fP, 96956, 'pressure value' );
   is( int await $fH, 41,    'humidity value' );
}

done_testing;
