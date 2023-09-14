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

{
   # GPIO
   $adapter->expect_readwrite( "\x41\x12\x00\x00" )
      ->returns( "\x00\x00\x5A\x1E" );

   is( await $chip->read_gpio( 0xff ), 0x5A,
      '->read_gpio initially' );

   $adapter->check_and_clear( '->read_gpio' );
}

# tris after write
{
   # IODIR
   $adapter->expect_write( "\x40\x00\x00" );
   # IODIR
   $adapter->expect_write( "\x40\x00\xFF" );

   await $chip->write_gpio( 0x00, 0xff );
   await $chip->tris_gpio( 0xff );

   $adapter->check_and_clear( '->read_gpio after ->write_gpio' );
}

done_testing;
