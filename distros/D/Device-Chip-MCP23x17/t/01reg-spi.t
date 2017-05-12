#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;


# ->write_reg
{
   $adapter->expect_write( "\x40\x01\x23" );

   $chip->write_reg( 0x01, chr 0x23 )->get;

   $adapter->check_and_clear( '$chip->write_reg' );
}

# ->read_reg
{
   $adapter->expect_readwrite( "\x41\x45\x00" )
      ->returns( "\x00\x00\x67" );

   is( $chip->read_reg( 0x45, 1 )->get, chr 0x67,
      '->read_reg returns register value' );

   $adapter->check_and_clear( '$chip->read_reg' );
}

done_testing;
