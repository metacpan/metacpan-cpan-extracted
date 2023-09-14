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

# ->chip_enable
{
   $adapter->expect_write_gpios( { CE => 1 } );

   await $chip->chip_enable( 1 );

   $adapter->check_and_clear( '$chip->chip_enable' );
}

# ->flush_rx_fifo
{
   $adapter->expect_readwrite( "\xE2" )->returns( "\x0E" );

   await $chip->flush_rx_fifo;

   $adapter->check_and_clear( '$chip->flush_rx_fifo' );
}

# ->flush_tx_fifo
{
   $adapter->expect_readwrite( "\xE1" )->returns( "\x0E" );

   await $chip->flush_tx_fifo;

   $adapter->check_and_clear( '$chip->flush_tx_fifo' );
}

done_testing;
