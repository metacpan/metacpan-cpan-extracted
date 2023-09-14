#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::nRF24L01P;

my $chip = Device::Chip::nRF24L01P->new;
my $adapter = Test::Device::Chip::Adapter->new;

$adapter->expect_write_gpios( { CE => 0 } );

await $chip->mount( $adapter );

# ->read_config
{
   # CONFIG - MASK_RX_DR=0, MASK_TX_DS=0, MASK_MAX_RT=0, EN_CRC=0, CRCO=1, PWR_UP=0, PRIM_RX=0
   $adapter->expect_readwrite( "\x00\x00" )->returns( "\x0E\x08" );
   # SETUP_AW - AW=5
   $adapter->expect_readwrite( "\x03\x00" )->returns( "\x0E\x03" );
   # SETUP_RETR - ARC=3, ARD=250us
   $adapter->expect_readwrite( "\x04\x00" )->returns( "\x0E\x03" );
   # RF_CH = 2
   $adapter->expect_readwrite( "\x05\x00" )->returns( "\x0E\x02" );
   # RF_SETUP - CONT_WAVE=0, RF_DR=2Mbps, PLL_LOCK=0, RF_PWR=0dBm
   $adapter->expect_readwrite( "\x06\x00" )->returns( "\x0E\x0E" );
   # TX_ADDR = "\xE7\xE7\xE7\xE7\xE7"
   $adapter->expect_readwrite( "\x10" . "\x00"x5 )->returns( "\x0E" . "\xE7"x5 );
   # FEATURE - EN_DPL=0, EN_ACK_PAY=0, EN_DYN_ACK=0
   $adapter->expect_readwrite( "\x1D\x00" )->returns( "\x0E\x00" );

   is( await $chip->read_config,
      {
         ARC         => 3,
         ARD         => 250,
         AW          => 5,
         CONT_WAVE   => !!0,
         CRCO        => 1,
         EN_ACK_PAY  => !!0,
         EN_CRC      => 1,
         EN_DPL      => !!0,
         EN_DYN_ACK  => !!0,
         MASK_MAX_RT => !!0,
         MASK_RX_DR  => !!0,
         MASK_TX_DS  => !!0,
         PLL_LOCK    => !!0,
         PRIM_RX     => !!0,
         PWR_UP      => !!0,
         RF_CH       => 2,
         RF_DR       => 2E6,
         RF_PWR      => 0,
         TX_ADDR     => "E7:E7:E7:E7:E7",
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );

   # No SPI

   is( $chip->latest_status,
      {
         MAX_RT  => !!0,
         RX_DR   => !!0,
         RX_P_NO => undef,
         TX_DS   => !!0,
         TX_FULL => !!0,
      },
      '$chip->latest_status after ->read_config'
   );
}

# ->change_config
{
   # Relies on caching from above

   # RF_CH
   $adapter->expect_readwrite( "\x25\x0F" )->returns( "\x0E\x00" );

   await $chip->change_config(
      RF_CH => 15,
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->read_rx_config
{
   # EN_AA
   $adapter->expect_readwrite( "\x01\x00" )->returns( "\x0E\x3F" );
   # EN_RXADDR
   $adapter->expect_readwrite( "\x02\x00" )->returns( "\x0E\x03" );
   # DYNPD
   $adapter->expect_readwrite( "\x1C\x00" )->returns( "\x0E\x00" );
   # RX_PW_P0
   $adapter->expect_readwrite( "\x11\x00" )->returns( "\x0E\x00" );
   # RX_ADDR_P0
   $adapter->expect_readwrite( "\x0A" . "\x00"x5 )->returns( "\x0E" . "\xC2"x5 );

   is( await $chip->read_rx_config( 0 ),
      {
         DYNPD     => !!0,
         EN_AA     => 1,
         EN_RXADDR => 1,
         RX_PW     => 0,
         RX_ADDR   => "C2:C2:C2:C2:C2",
      },
      '$chip->read_rx_config'
   );

   $adapter->check_and_clear( '$chip->read_rx_config' );
}

# ->change_rx_config
{
   # Relies on caching from above

   $adapter->expect_readwrite( "\x31\x04" )->returns( "\x0E\x00" );

   await $chip->change_rx_config( 0,
      RX_PW => 4,
   );

   $adapter->check_and_clear( '$chip->change_rx_config' );
}

done_testing;
