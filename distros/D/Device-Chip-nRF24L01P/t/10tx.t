#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::nRF24L01P;

my $chip = Device::Chip::nRF24L01P->new;
my $adapter = Test::Device::Chip::Adapter->new;

$adapter->expect_write_gpios( { CE => 0 } );

await $chip->mount( $adapter );

# ->write_tx_payload
{
   $adapter->expect_readwrite( "\xA0hello" )->returns( "\x0E\0\0\0\0\0" );

   await $chip->write_tx_payload( "hello" );

   $adapter->check_and_clear( '$chip->write_tx_payload' );
}

# ->write_tx_payload no_ack
{
   $adapter->expect_readwrite( "\xB0hello" )->returns( "\x0E\0\0\0\0\0" );

   await $chip->write_tx_payload( "hello", no_ack => 1 );

   $adapter->check_and_clear( '$chip->write_tx_payload +no_ack' );
}

done_testing;
