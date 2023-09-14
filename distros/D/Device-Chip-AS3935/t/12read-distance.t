#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AS3935;

my $chip = Device::Chip::AS3935->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write_then_read( "\x07", 1 )
      ->returns( "\x3F" );

   is( await $chip->read_distance, undef,
      '$chip->read_distance too far'
   );

   $adapter->expect_write_then_read( "\x07", 1 )
      ->returns( "\x0E" );

   is( await $chip->read_distance, 14,
      '$chip->read_distance 14km'
   );

   $adapter->check_and_clear( '$chip->read_distance' );
}

done_testing;
