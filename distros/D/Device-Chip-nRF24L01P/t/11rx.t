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

# ->read_rx_payload_width
{
   $adapter->expect_readwrite( "\x60\x00" )->returns( "\x0E\x07" );

   is( await $chip->read_rx_payload_width, 7, '$chip->read_rx_payload_width' );

   $adapter->check_and_clear( '$chip->read_rx_payload_width' );
}

# ->read_rx_payload
{
   $adapter->expect_readwrite( "\x61" . "\0"x7 )->returns( "\x0Emessage" );

   is( await $chip->read_rx_payload( 7 ), "message", '$chip->read_rx_payload' );

   $adapter->check_and_clear( '$chip->read_rx_payload' );
}

done_testing;
