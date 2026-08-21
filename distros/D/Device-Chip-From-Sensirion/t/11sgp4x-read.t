#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SGP4x;

my $chip = Device::Chip::SGP4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   $adapter->expect_write( "\x26\x12\x80\x00\xA2\x66\x66\x93" );
   $adapter->expect_sleep( 0.050 );
   $adapter->expect_read( 3 )
      ->will_done( "\x5B\xA0\x80" );

   await $chip->execute_conditioning;

   $adapter->check_and_clear( '->execute_conditioning' );
}

{
   $adapter->expect_write( "\x26\x19\x80\x00\xA2\x66\x66\x93" );
   $adapter->expect_sleep( 0.050 );
   $adapter->expect_read( 6 )
      ->will_done( "\x5B\xA0\x80" . "\x87\x07\x9B" );

   is( [ await $chip->measure_raw_signals ], [ 23456, 34567 ],
      '->measure_raw_signals yields correct measurement values' );

   $adapter->check_and_clear( '->measure_raw_signals' );
}

{
   $adapter->expect_write( "\x26\x19\x99\x99\xBE\x6A\xC9\xF5" );
   $adapter->expect_sleep( 0.050 );
   $adapter->expect_read( 6 )
      ->will_done( "\x70\x62\x63" . "\x4E\xED\xE8" );

   is( [ await $chip->measure_raw_signals( temperature => 28, humidity => 60 ) ],
       [ 28770, 20205 ],
      '->measure_raw_signals handles compensation values' );

   $adapter->check_and_clear( '->measure_raw_signals with compensation' );
}

done_testing;
