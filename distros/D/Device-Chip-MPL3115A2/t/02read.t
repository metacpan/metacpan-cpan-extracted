#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MPL3115A2;

my $chip = Device::Chip::MPL3115A2->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# check_id
{
   $adapter->expect_write_then_read( "\x0C", 1 )
      ->returns( "\xC4" );

   ok( await $chip->check_id, '$chip->check_id' );

   $adapter->check_and_clear( '$chip->check_id' );
}

# read_pressure
{
   $adapter->expect_write_then_read( "\x01", 3 )
      ->returns( "\x62\xF3\x40" );

   is( await $chip->read_pressure, 101325,
      '$chip->read_pressure yields pressure in Pascals' );

   $adapter->check_and_clear( '$chip->read_pressure' );
}

# read_altitude
{
   # On a real chip you'd have to set ALT mode first, but we don't care for this test
   $adapter->expect_write_then_read( "\x01", 3 )
      ->returns( "\x00\x14\x00" );

   is( await $chip->read_altitude, 20,
      '$chip->read_altitude yields altitude in metres' );

   $adapter->check_and_clear( '$chip->read_altitude' );
}

# read_temperature
{
   $adapter->expect_write_then_read( "\x04", 2 )
      ->returns( "\x16\x80" );

   is( await $chip->read_temperature, 22.5,
      '$chip->read_temperature yields temperature in C' );

   $adapter->check_and_clear( '$chip->read_temperature' );
}

done_testing;
