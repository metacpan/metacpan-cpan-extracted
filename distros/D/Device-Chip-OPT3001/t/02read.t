#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::OPT3001;

my $chip = Device::Chip::OPT3001->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_lux
{
   $adapter->expect_write_then_read( "\x00", 2 )
      ->returns( "\x91\x23" );

   is( await $chip->read_lux, 1489.92, '->read_lux returns value' );

   $adapter->check_and_clear( '->read_lux' );
}

done_testing;
