#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AS3935;

my $chip = Device::Chip::AS3935->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   # reset
   $adapter->expect_write( "\x3C" . "\x96" );
   # calibrate_rco
   $adapter->expect_write( "\x3D" . "\x96" );

   await $chip->initialize_sensors;

   $adapter->check_and_clear( '$chip->initialize_sensors' );
}

my @sensors = $chip->list_sensors;

is( scalar @sensors, 4, '$chip->list_sensors returns 1 sensor' );

{
   my $sensor = $sensors[2];

   is( $sensor->name,  "lightning_strike_events", '$sensor->name' );
   is( $sensor->type, "counter",                  '$sensor->type' );
   is( $sensor->units, undef,                     '$sensor->units' );

   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x08" );

   is( $sensor->format( scalar await $sensor->read ), "1",
      '$sensor->read+format' );

   $adapter->check_and_clear( '$sensor->read' );
}

{
   my $sensor = $sensors[3];

   is( $sensor->name,  "lightning_distance", '$sensor->name' );
   is( $sensor->units, "km",                 '$sensor->units' );

   $adapter->expect_write_then_read( "\x07", 1 )
      ->returns( "\x0E" );

   is( $sensor->format( scalar await $sensor->read ), "14",
      '$sensor->read+format' );

   $adapter->check_and_clear( 'distance $sensor->read' );
}

done_testing;
