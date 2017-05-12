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


{
   # GPIO
   $adapter->expect_readwrite( "\x41\x12\x00\x00" )
      ->returns( "\x00\x00\x5A\x1E" );

   is( $chip->read_gpio( 0xff )->get, 0x5A,
      '->read_gpio initially' );

   $adapter->check_and_clear( '->read_gpio' );
}

# tris after write
{
   # IODIR
   $adapter->expect_write( "\x40\x00\x00" );
   # IODIR
   $adapter->expect_write( "\x40\x00\xFF" );

   $chip->write_gpio( 0x00, 0xff )->get;
   $chip->tris_gpio( 0xff )->get;

   $adapter->check_and_clear( '->read_gpio after ->write_gpio' );
}

done_testing;
