#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SCD4x;

my $chip = Device::Chip::SCD4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x21\xB1" );

   await $chip->start_periodic_measurement;

   $adapter->check_and_clear( '->start_periodic_measurement' );
}

{
   $adapter->expect_write_then_read( "\xEC\x05", 9 )
      # Example in data sheet has bad CRC here; CRC0 should be 0x33, not 0x7B
      ->will_done( "\x01\xF4\x33\x66\x67\xA2\x5E\xB9\x3C" );

   is( [ await $chip->read_measurement ], [ 500, rounded(25.0, 2), rounded(37.0, 2) ],
      '->read_measurement yields correct measurement values' );

   $adapter->check_and_clear( '->read_measurement' );
}

done_testing;
