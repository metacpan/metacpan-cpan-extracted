#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter;
use Test::ExpectAndCheck::Future 0.02;  # deferred results

use Future::AsyncAwait;

use Device::Chip::MPL3115A2;

my $chip = Device::Chip::MPL3115A2->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# precache config
{
   $adapter->expect_write_then_read( "\x26", 3 )
      ->will_done( "\x00\x00\x00" );

   await $chip->read_config;
}

my @sensors = $chip->list_sensors;

is( scalar @sensors, 2, '$chip->list_sensors returns 2 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

# temperature sensor
{
   my $sensor = $sensors{temperature};

   is( $sensor->units, "°C", 'temperature $sensor->units' );

   # Trigger oneshot
   $adapter->expect_write( "\x26" . "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x00" );

   $adapter->expect_write_then_read( "\x04", 2 )
      ->will_done( "\x16\x80" );

   is( $sensor->format( scalar await $sensor->read ), "22.50",
      'temperature $sensor->read+format' );

   $adapter->check_and_clear( 'temperature $sensor->read' );
}

# pressure sensor
{
   my $sensor = $sensors{pressure};

   is( $sensor->units, "pascals", 'pressure $sensor->units' );

   # Trigger oneshot
   $adapter->expect_write( "\x26" . "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x00" );

   $adapter->expect_write_then_read( "\x01", 3 )
      ->will_done( "\x62\xF3\x40" );

   is( $sensor->format( scalar await $sensor->read ), "101325",
      'pressure $sensor->read+format' );

   $adapter->check_and_clear( 'pressure $sensor->read' );
}

# sensors concurrently
{
   # Expect just a single trigger oneshot
   $adapter->expect_write( "\x26" . "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x02" );
   $adapter->expect_write_then_read( "\x26", 1 )
      ->will_done( "\x00" );

   $adapter->expect_write_then_read( "\x04", 2 )
      ->will_done( "\x16\x80" );
   $adapter->expect_write_then_read( "\x01", 3 )
      ->will_done( "\x62\xF3\x40" );

   my $fT = $sensors{temperature}->read;
   my $fP = $sensors{pressure}->read;

   is( int await $fT, 22,     'temperature value' );
   is( int await $fP, 101325, 'pressure value' );
}

done_testing;
