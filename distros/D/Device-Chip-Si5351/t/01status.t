#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::Si5351;

my $chip = Device::Chip::Si5351->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_status
{
   $adapter->expect_write_then_read( "\x00", 1 )
      ->returns( "\x11" );

   is( await $chip->read_status,
      {
         SYS_INIT  => '',
         LOL_B     => '',
         LOL_A     => '',
         LOS_CLKIN => 1,
         LOS_XTAL  => '',
         REVID     => 1,
      },
      '->read_status yields status' );

   $adapter->check_and_clear( '->read_status' );
}

done_testing;
