#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
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
      ->will_done( Device::Chip::CC1101->CONFIG_DEFAULT );
   # PATABLE
   $adapter->expect_write_then_read( "\xFE", 8 )
      ->will_done( "\xC6\x00\x00\x00\x00\x00\x00\x00" );

   await $chip->read_config;
}

# ->transmit in fixed length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x46" . "\x04\x04\x44" );

   await $chip->change_config(
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 4,
   );

   # CMD_SIDLE
   $adapter->expect_write( "\x36" );
   # read MARCSTATE, returns IDLE
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->will_done( "\x01" );
   # CMD_STX
   $adapter->expect_write( "\x35" );
   # read MARCSTATE, returns TX
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->will_done( "\x13" );
   # write TXFIFO
   $adapter->expect_write( "\x7F" . "ABCD" );
   # read chip status, returns IDLE
   $adapter->expect_readwrite( "\x3D" )
      ->will_done( "\x0F" );

   await $chip->transmit( "ABCD" );

   $adapter->check_and_clear( '->transmit fixed-length' );
}

# ->transmit in variable-length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x48" . "\x45" );

   await $chip->change_config(
      LENGTH_CONFIG => "variable",
   );

   # CMD_SIDLE
   $adapter->expect_write( "\x36" );
   # read MARCSTATE, returns IDLE
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->will_done( "\x01" );
   # CMD_STX
   $adapter->expect_write( "\x35" );
   # read MARCSTATE, returns TX
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->will_done( "\x13" );
   # write TXFIFO
   $adapter->expect_write( "\x7F" . "\x04EFGH" );
   # read chip status, returns IDLE
   $adapter->expect_readwrite( "\x3D" )
      ->will_done( "\x0F" );

   await $chip->transmit( "EFGH" );

   $adapter->check_and_clear( '->transmit variable-length' );
}

done_testing;
