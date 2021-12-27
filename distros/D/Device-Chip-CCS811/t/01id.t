#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::CCS811;

my $chip = Device::Chip::CCS811->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_id
{
   $adapter->expect_write_then_read( "\x20", 1 )
      ->returns( "\x81" );

   is( await $chip->read_id, 0x81,
      '->read_id yields correct chip ID' );

   $adapter->check_and_clear( '->read_id' );
}

done_testing;
