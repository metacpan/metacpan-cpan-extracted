#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::HTU21D;

my $chip = Device::Chip::HTU21D->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my @sensors = $chip->list_sensors;

is( scalar @sensors, 2, '$chip->list_sensors returns 2 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

# temperature sensor
{
   my $sensor = $sensors{temperature};

   is( $sensor->units, "°C", 'temperature $sensor->units' );

   $adapter->expect_write( "\xF3" );
   $adapter->expect_read( 2 )
      ->returns( "\x5D\x20" );

   is( $sensor->format( scalar await $sensor->read ), "17.07",
      'temperature $sensor->read+format' );

   $adapter->check_and_clear( 'temperature $sensor->read' );
}

# humidity sensor
{
   my $sensor = $sensors{humidity};

   is( $sensor->units, "%RH", 'humidity $sensor->units' );

   $adapter->expect_write( "\xF5" );
   $adapter->expect_read( 2 )
      ->returns( "\x5A\x2C" );

   is( $sensor->format( scalar await $sensor->read ), "38.0",
      'humidity $sensor->read+format' );

   $adapter->check_and_clear( 'humidity $sensor->read' );
}

# sensors concurrently
{
   $adapter->expect_write( "\xF3" );
   $adapter->expect_read( 2 )
      ->returns( "\x6D\x20" );
   $adapter->expect_write( "\xF5" );
   $adapter->expect_read( 2 )
      ->returns( "\x6A\x2C" );

   my $fT = $sensors{temperature}->read;
   my $fH = $sensors{humidity}->read;

   is( int await $fT, 28, 'temperature value' );
   is( int await $fH, 45, 'humidity value' );
}

done_testing;
