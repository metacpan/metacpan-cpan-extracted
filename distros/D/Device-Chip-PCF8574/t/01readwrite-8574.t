#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Device::Chip::PCF8574;

my $chip = Device::Chip::PCF8574->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->write
{
   $adapter->expect_write( "\x55" );

   $chip->write( 0x55 )->get;

   $adapter->check_and_clear( '$chip->write' );
}

# ->read
{
   $adapter->expect_read( 1 )->returns( "\xAA" );

   is( $chip->read->get, 0xAA, '$chip->read returns value' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
