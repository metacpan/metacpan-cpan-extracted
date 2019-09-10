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

# ->read_register
{
   # FIFOTHR
   $adapter->expect_write_then_read( "\x83", 1 )
      ->returns( "\x07" );

   is( $chip->read_register( 0x03 )->get, 0x07,
      '->read_register yields value' );

   $adapter->check_and_clear( '->read_register' );

   # VERSION is a status register so gets REG_BURST set
   $adapter->expect_write_then_read( "\xF1", 1 )
      ->returns( "\x14" );

   is( $chip->read_register( 0x31 )->get, 0x14,
      '->read_register yields value' );

   $adapter->check_and_clear( '->read_register on status register' );
}

# ->read_marcstate
{
   $adapter->expect_write_then_read( "\xF5", 1 )
      ->returns( "\x01" );

   is( $chip->read_marcstate->get, "IDLE",
      '->read_marcstate yields string name' );

   $adapter->check_and_clear( '->read_marcstate' );
}

# ->read_chipstatus_*
{
   $adapter->expect_readwrite( "\xBD" )
      ->returns( "\x10" );

   is_deeply( $chip->read_chipstatus_rx->get,
      { STATE => "RX", FIFO_BYTES_AVAILABLE => 0 },
      '->read_chipstatus_rx yields status' );

   $adapter->expect_readwrite( "\x3D" )
      ->returns( "\x2F" );

   is_deeply( $chip->read_chipstatus_tx->get,
      { STATE => "TX", FIFO_BYTES_AVAILABLE => 15 },
      '->read_chipstatus_tx yields status' );

   $adapter->check_and_clear( '->read_chipstatus_*' );
}

# ->read_pktstatus
{
   $adapter->expect_write_then_read( "\xF8", 1 )
      ->returns( "\x30" );

   is_deeply( $chip->read_pktstatus->get,
      { CCA => 1, CRC_OK => '', CS => '', GDO0 => '', GDO2 => '', PQT_REACHED => 1, SFD => '' },
      '->read_pktstatus yields status' );

   $adapter->check_and_clear( '->read_pktstatus' );
}

done_testing;
