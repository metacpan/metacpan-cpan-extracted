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

# ->observe_tx_counts
{
   # OBSERVE_TX
   $adapter->expect_readwrite( "\x08\x00" )->returns( "\x0E\x12" );

   is( await $chip->observe_tx_counts,
      {
         ARC_CNT  => 2,
         PLOS_CNT => 1,
      },
      '$chip->observe_tx_counts'
   );

   $adapter->check_and_clear( '$chip->observe_tx_counts' );
}

# ->rpd
{
   # RPD
   $adapter->expect_readwrite( "\x09\x00" )->returns( "\x0E\x01" );

   is( await $chip->rpd, 1, '$chip->rpd' );

   $adapter->check_and_clear( '$chip->rpd' );
}

# ->fifo_status
{
   # FIFO_STATUS
   $adapter->expect_readwrite( "\x17\x00" )->returns( "\x0E\x11" );

   is( await $chip->fifo_status,
      {
         RX_EMPTY => 1,
         RX_FULL  => !!0,

         TX_EMPTY => 1,
         TX_FULL  => !!0,
         TX_REUSE => !!0,
      },
      '$chip->fifo_status'
   );

   $adapter->check_and_clear( '$chip->fifo_status' );
}

done_testing;
