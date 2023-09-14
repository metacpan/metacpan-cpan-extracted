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

$chip->enable_agc( 1 );

# switch to high gain
{
   $adapter->expect_write_then_read( "\x80", 1 )
      ->returns( "\x00" );
   $adapter->expect_write_then_read( "\x81", 1 )
      ->returns( "\x02" );

   # read_config first just to cache the GAIN/INTEG settings
   await $chip->read_config;

   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x89\x00\x88\x00" );
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x89\x00\x88\x00" );
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x89\x00\x88\x00" );
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x89\x00\x88\x00" );

   $adapter->expect_write( "\x81\x12" );

   # four reads in a row should switch to GAIN=16
   await $chip->read_lux;
   await $chip->read_lux;
   await $chip->read_lux;
   await $chip->read_lux;

   $adapter->check_and_clear( '$chip->read_lux low values switches to GAIN=16' );
}

# switch to low gain immediately
{
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x00\xC0\x88\x00" );

   $adapter->expect_write( "\x81\x02" );

   await $chip->read_lux;

   $adapter->check_and_clear( '$chip->read_lux high values switches to GAIN=1' );
}

done_testing;
