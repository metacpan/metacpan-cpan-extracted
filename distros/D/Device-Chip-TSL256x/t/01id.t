#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TSL256x;

my $chip = Device::Chip::TSL256x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_write_then_read( "\x8A", 1 )
      ->returns( "\x50" );

   is( $chip->read_id->get, 0x50,
      '->read_id returns chip ID' );

   $adapter->check_and_clear( '$chip->read_id' );
}

done_testing;
