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

# ->read_status
{
   $adapter->expect_write_then_read( "\x00", 1 )
      ->returns( "\x00" );

   is( await $chip->read_status,
      {
         APP_ERASE  => '',
         APP_VALID  => '',
         APP_VERIFY => '',
         DATA_READY => '',
         ERROR      => '',
         FWMODE     => "boot",
      },
      '->read_status yields boot status' );

   $adapter->check_and_clear( '->read_status' );
}

# ->init
{
   $adapter->expect_write_then_read( "\x00", 1 )
      ->returns( "\x00" );
   $adapter->expect_write( "\xF4" )
      ->returns();
   $adapter->expect_write_then_read( "\x00", 1 )
      ->returns( "\x80" );

   await $chip->init;

   is( await $chip->read_status,
      {
         APP_ERASE  => '',
         APP_VALID  => '',
         APP_VERIFY => '',
         DATA_READY => '',
         ERROR      => '',
         FWMODE     => "app",
      },
      '->read_status yields app status after ->init' );

   $adapter->check_and_clear( '->init' );
}

done_testing;
