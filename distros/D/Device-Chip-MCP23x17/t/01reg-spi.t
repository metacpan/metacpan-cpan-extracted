#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MCP23S17;

my $chip = Device::Chip::MCP23S17->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->write_reg
{
   $adapter->expect_write( "\x40\x01\x23" );

   await $chip->write_reg( 0x01, chr 0x23 );

   $adapter->check_and_clear( '$chip->write_reg' );
}

# ->read_reg
{
   $adapter->expect_readwrite( "\x41\x45\x00" )
      ->returns( "\x00\x00\x67" );

   is( await $chip->read_reg( 0x45, 1 ), chr 0x67,
      '->read_reg returns register value' );

   $adapter->check_and_clear( '$chip->read_reg' );
}

done_testing;
