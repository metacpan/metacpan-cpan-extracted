#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::CCS811;

my $chip = Device::Chip::CCS811->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x01", 1 )
      ->returns( "\x00" );

   is_deeply( await $chip->read_config,
      {
         DRIVE_MODE  => 0,
         INT_DATARDY => '',
         INT_THRESH  => '',
      },
      '->read_config yields default config' );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x01\x10" )
      ->returns();

   await $chip->change_config( DRIVE_MODE => 1 );

   # cached a second time
   is_deeply( await $chip->read_config,
      {
         DRIVE_MODE  => 1,
         INT_DATARDY => '',
         INT_THRESH  => '',
      },
      '->read_config yields config after ->change_config' );

   $adapter->check_and_clear( '->change_config' );
}

done_testing;
