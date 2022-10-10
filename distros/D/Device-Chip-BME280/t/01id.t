#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BME280;

my $chip = Device::Chip::BME280->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_id
{
   $adapter->expect_write_then_read( "\xD0", 1 )
      ->will_done( "\x60" );

   is( await $chip->read_id, 0x60,
      '->read_id yields correct chip ID' );

   $adapter->check_and_clear( '->read_id' );
}

done_testing;
