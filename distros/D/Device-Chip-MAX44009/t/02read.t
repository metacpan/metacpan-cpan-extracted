#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter 0.18;

use Future::AsyncAwait;

use Device::Chip::MAX44009;

my $chip = Device::Chip::MAX44009->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_lux
{
   $adapter->expect_txn_start;
   $adapter->expect_write_then_read( "\x03", 1 )
      ->returns( "\x87" );
   $adapter->expect_write_then_read( "\x04", 1 )
      ->returns( "\x06" );
   $adapter->expect_txn_stop;

   is( await $chip->read_lux, 1888, '->read_lux returns value' );

   $adapter->check_and_clear( '->read_lux' );
}

done_testing;
