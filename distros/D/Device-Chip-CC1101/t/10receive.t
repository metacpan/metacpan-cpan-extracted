#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::CC1101;

my $chip = Device::Chip::CC1101->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# initialise config
{
   # CONFIG
   $adapter->expect_write_then_read( "\xC0", 41 )
      ->returns( Device::Chip::CC1101->CONFIG_DEFAULT );
   # PATABLE
   $adapter->expect_write_then_read( "\xFE", 8 )
      ->returns( "\xC6\x00\x00\x00\x00\x00\x00\x00" );

   await $chip->read_config;
}

# ->receive in fixed length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x46" . "\x04\x04\x44" );

   await $chip->change_config(
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 4,
   );

   # read RXFIFO, returns packet
   $adapter->expect_write_then_read( "\xFB", 1 )
      ->returns( "\x06" );
   $adapter->expect_write_then_read( "\xFF", 6 )
      ->returns( "ABCD\x30\xA0" );

   is_deeply( await $chip->receive,
      {
         data   => "ABCD",
         CRC_OK => 1,
         LQI    => 32,
         RSSI   => -50,
      },
      '->receive yields packet'
   );

   $adapter->check_and_clear( '->receive fixed-length' );
}

# ->receive in variable-length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x48" . "\x45" );

   await $chip->change_config(
      LENGTH_CONFIG => "variable",
   );

   # read RXFIFO, returns length
   $adapter->expect_write_then_read( "\xFB", 1 )
      ->returns( "\x01" );
   $adapter->expect_write_then_read( "\xFF", 1 )
      ->returns( "\x04" );
   # read RXFIFO, returns packet
   $adapter->expect_write_then_read( "\xFB", 1 )
      ->returns( "\x06" );
   $adapter->expect_write_then_read( "\xFF", 6 )
      ->returns( "EFGH\x32\xA1" );

   is_deeply( await $chip->receive,
      {
         data   => "EFGH",
         CRC_OK => 1,
         LQI    => 33,
         RSSI   => -49,
      },
      '->receive yields packet'
   );

   $adapter->check_and_clear( '->receive variable-length' );
}

done_testing;
