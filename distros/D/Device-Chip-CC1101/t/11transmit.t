#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::CC1101;

my $chip = Device::Chip::CC1101->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# initialise config
{
   # CONFIG
   $adapter->expect_write_then_read( "\xC0", 41 )
      ->returns( Device::Chip::CC1101->CONFIG_DEFAULT );
   # PATABLE
   $adapter->expect_write_then_read( "\xFE", 8 )
      ->returns( "\xC6\x00\x00\x00\x00\x00\x00\x00" );

   $chip->read_config->get;
}

# ->transmit in fixed length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x46" . "\x04\x04\x44" );

   $chip->change_config(
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 4,
   )->get;

   # CMD_SIDLE
   $adapter->expect_write( "\x36" );
   # read MARCSTATE, returns IDLE
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   # CMD_STX
   $adapter->expect_write( "\x35" );
   # read MARCSTATE, returns TX
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x13" );
   # write TXFIFO
   $adapter->expect_write( "\x7F" . "ABCD" );
   # read chip status, returns IDLE
   $adapter->expect_readwrite( "\x3D" )
      ->returns( "\x0F" );

   $chip->transmit( "ABCD" )->get;

   $adapter->check_and_clear( '->transmit fixed-length' );
}

# ->transmit in variable-length configuration
{
   # Update CONFIG
   $adapter->expect_write( "\x48" . "\x45" );

   $chip->change_config(
      LENGTH_CONFIG => "variable",
   )->get;

   # CMD_SIDLE
   $adapter->expect_write( "\x36" );
   # read MARCSTATE, returns IDLE
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );
   # CMD_STX
   $adapter->expect_write( "\x35" );
   # read MARCSTATE, returns TX
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x13" );
   # write TXFIFO
   $adapter->expect_write( "\x7F" . "\x04EFGH" );
   # read chip status, returns IDLE
   $adapter->expect_readwrite( "\x3D" )
      ->returns( "\x0F" );

   $chip->transmit( "EFGH" )->get;

   $adapter->check_and_clear( '->transmit variable-length' );
}

done_testing;
