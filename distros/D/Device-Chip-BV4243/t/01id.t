#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BV4243;

my $chip = Device::Chip::BV4243->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->device_id
{
   $adapter->expect_write_then_read( "\xA1", 2 )
      ->returns( "\x10\x93" );

   is( await $chip->device_id, 4243,
      '->device_id yields correct chip ID' );

   $adapter->check_and_clear( '->device_id' );
}

# ->version
{
   $adapter->expect_write_then_read( "\xA0", 2 )
      ->returns( "\x04\xD2" );

   is( await $chip->version, 1234,
      '->version yields correct chip version' );

   $adapter->check_and_clear( '->version' );
}

done_testing;
