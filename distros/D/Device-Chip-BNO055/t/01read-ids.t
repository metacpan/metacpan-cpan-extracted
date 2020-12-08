#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BNO055;

my $chip = Device::Chip::BNO055->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_ids
{
   $adapter->expect_write_then_read( "\x00", 4 )
      ->returns( "\xA0\xFB\x32\x0F" );

   is( await $chip->read_ids, "A0FB320F",
      '->read_ids yields correct chip ID' );

   $adapter->check_and_clear( '->read_ids' );
}

done_testing;
