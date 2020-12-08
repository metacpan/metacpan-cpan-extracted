#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

{
   # IPOL
   $adapter->expect_write( "\x40\x02\x20" );

   await $chip->set_input_polarity( 0x20, 0xF0 );

   $adapter->check_and_clear( '->set_input_polarity' );
}

{
   # GPPU
   $adapter->expect_write( "\x40\x0C\x40" );

   await $chip->set_input_pullup( 0x40, 0xF0 );

   $adapter->check_and_clear( '->set_input_pullup' );
}

done_testing;
