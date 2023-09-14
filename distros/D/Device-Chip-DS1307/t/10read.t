#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::DS1307;

my $chip = Device::Chip::DS1307->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_time
{
   $adapter->expect_write_then_read( "\x00", 7 )
      ->returns( "\x56\x34\x12\x00\x07\x08\x90" );

   is( [ await $chip->read_time ],
      [ 56, 34, 12, 7, 7, 190, 0 ],
      '$chip->read_time' );

   $adapter->check_and_clear( '$chip->read_time' );
}

done_testing;
