#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::nRF24L01P;

my $chip = Device::Chip::nRF24L01P->new;
my $adapter = Test::Device::Chip::Adapter->new;

$adapter->expect_write_gpios( { CE => 0 } );

$chip->mount( $adapter )->get;

# ->chip_enable
{
   $adapter->expect_write_gpios( { CE => 1 } );

   $chip->chip_enable( 1 )->get;

   $adapter->check_and_clear( '$chip->chip_enable' );
}

# ->flush_rx_fifo
{
   $adapter->expect_readwrite( "\xE2" )->returns( "\x0E" );

   $chip->flush_rx_fifo->get;

   $adapter->check_and_clear( '$chip->flush_rx_fifo' );
}

# ->flush_tx_fifo
{
   $adapter->expect_readwrite( "\xE1" )->returns( "\x0E" );

   $chip->flush_tx_fifo->get;

   $adapter->check_and_clear( '$chip->flush_tx_fifo' );
}

done_testing;
