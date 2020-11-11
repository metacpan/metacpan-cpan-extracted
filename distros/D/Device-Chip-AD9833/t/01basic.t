#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::AD9833;

my $chip = Device::Chip::AD9833->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->init
{
   $adapter->expect_write( "\x21\x00" ); # B28, RESET
   $adapter->expect_write( "\x20\x00" ); # B28

   $chip->init->get;

   $adapter->check_and_clear( '->init' );
}

# ->write_FREQ0
{
   $adapter->expect_write( "\x45\x67" ); # FREQ0L
   $adapter->expect_write( "\x44\x8D" ); # FREQ0H

   $chip->write_FREQ0( 0x1234567 )->get;

   $adapter->check_and_clear( '->write_FREQ0' );
}

# ->write_PHASE0
{
   $adapter->expect_write( "\xC8\x9A" ); # PHASE0

   $chip->write_PHASE0( 0x89A )->get;

   $adapter->check_and_clear( '->write_FREQ0' );
}

done_testing;
