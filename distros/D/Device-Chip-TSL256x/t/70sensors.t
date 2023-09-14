#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x80\x03" );  # POWER on
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );

   $adapter->expect_sleep( "0.402" ); # startup delay

   await $chip->initialize_sensors;

   $adapter->check_and_clear( '$chip->initialize_sensors' );
}

my @sensors = $chip->list_sensors;

is( scalar @sensors, 1, '$chip->list_sensors returns 1 sensor' );

my $sensor = $sensors[0];

{
   is( $sensor->name,  "light", '$sensor->name' );
   is( $sensor->units, "lux",   '$sensor->units' );

   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x00\x04\x00\x02" );

   is( $sensor->format( scalar await $sensor->read ), "113.15",
      '$sensor->read+format' );

   $adapter->check_and_clear( '$sensor->read' );
}

done_testing;
