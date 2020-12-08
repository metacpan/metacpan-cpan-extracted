#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write_then_read( "\x8A", 1 )
      ->returns( "\x50" );

   is( await $chip->read_id, 0x50,
      '->read_id returns chip ID' );

   $adapter->check_and_clear( '$chip->read_id' );
}

done_testing;
