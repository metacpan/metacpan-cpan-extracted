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

# ->read_rx_payload_width
{
   $adapter->expect_readwrite( "\x60\x00" )->returns( "\x0E\x07" );

   is( $chip->read_rx_payload_width->get, 7, '$chip->read_rx_payload_width' );

   $adapter->check_and_clear( '$chip->read_rx_payload_width' );
}

# ->read_rx_payload
{
   $adapter->expect_readwrite( "\x61" . "\0"x7 )->returns( "\x0Emessage" );

   is( $chip->read_rx_payload( 7 )->get, "message", '$chip->read_rx_payload' );

   $adapter->check_and_clear( '$chip->read_rx_payload' );
}

done_testing;
