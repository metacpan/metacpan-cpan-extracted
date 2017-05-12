#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.08;  # ->read

use Device::Chip::PCF8575;

my $chip = Device::Chip::PCF8575->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->write
{
   $adapter->expect_write( "\x34\x12" );

   $chip->write( 0x1234 )->get;

   $adapter->check_and_clear( '$chip->write' );
}

# ->read
{
   $adapter->expect_read( 2 )->returns( "\xAB\xCD" );

   is( $chip->read->get, 0xCDAB, '$chip->read returns value' );

   $adapter->check_and_clear( '$chip->read' );
}

done_testing;
