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
   # IPOL
   $adapter->expect_write( "\x40\x02\x20" );

   $chip->set_input_polarity( 0x20, 0xF0 )->get;

   $adapter->check_and_clear( '->set_input_polarity' );
}

{
   # GPPU
   $adapter->expect_write( "\x40\x0C\x40" );

   $chip->set_input_pullup( 0x40, 0xF0 )->get;

   $adapter->check_and_clear( '->set_input_pullup' );
}


done_testing;
