#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TCS3472x;

use Future::AsyncAwait;

my $chip = Device::Chip::TCS3472x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_ids
{
   $adapter->expect_write_then_read( "\xB2", 1 )
      ->returns( "\x44" );

   is( await $chip->read_id, "44",
      '->read_ids yields correct chip ID' );

   $adapter->check_and_clear( '->read_ids' );
}

done_testing;
