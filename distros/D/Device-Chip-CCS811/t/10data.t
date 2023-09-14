#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::CCS811;

my $chip = Device::Chip::CCS811->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_alg_result_data
{
   $adapter->expect_write_then_read( "\x02", 6 )
      ->returns( "\x01\xAA\x00\x05\x98\x00" );

   is( await $chip->read_alg_result_data,
      {
         # STATUS fields
         APP_ERASE  => '',
         APP_VALID  => 1,
         APP_VERIFY => '',
         DATA_READY => 1,
         ERROR      => '',
         ERROR_ID   => 0,
         FWMODE     => "app",

         eCO2  => 426,
         eTVOC => 5,
      },
      '->read_alg_result_data yields data' );

   $adapter->check_and_clear( '->read_alg_result_data' );
}

done_testing;
