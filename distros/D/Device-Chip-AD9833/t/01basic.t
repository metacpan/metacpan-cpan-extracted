#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AD9833;

my $chip = Device::Chip::AD9833->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->init
{
   $adapter->expect_write( "\x21\x00" ); # B28, RESET
   $adapter->expect_write( "\x20\x00" ); # B28

   await $chip->init;

   $adapter->check_and_clear( '->init' );
}

# ->write_FREQ0
{
   $adapter->expect_write( "\x45\x67" ); # FREQ0L
   $adapter->expect_write( "\x44\x8D" ); # FREQ0H

   await $chip->write_FREQ0( 0x1234567 );

   $adapter->check_and_clear( '->write_FREQ0' );
}

# ->write_PHASE0
{
   $adapter->expect_write( "\xC8\x9A" ); # PHASE0

   await $chip->write_PHASE0( 0x89A );

   $adapter->check_and_clear( '->write_FREQ0' );
}

done_testing;
