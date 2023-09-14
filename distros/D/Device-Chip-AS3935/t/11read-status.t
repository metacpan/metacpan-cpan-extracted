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
   $adapter->expect_write_then_read( "\x3A", 2 )
      ->returns( "\x00\x00" );

   is( await $chip->read_calib_status,
      {
         TRCO_CALIB_DONE => '', TRCO_CALIB_NOK => '',
         SRCO_CALIB_DONE => '', SRCO_CALIB_NOK => '',
      },
      '$chip->read_calib_status not done'
   );

   $adapter->expect_write_then_read( "\x3A", 2 )
      ->returns( "\x80\x80" );

   is( await $chip->read_calib_status,
      {
         TRCO_CALIB_DONE => 1, TRCO_CALIB_NOK => '',
         SRCO_CALIB_DONE => 1, SRCO_CALIB_NOK => '',
      },
      '$chip->read_calib_status done'
   );

   $adapter->check_and_clear( '$chip->read_calib_status' );
}

done_testing;
