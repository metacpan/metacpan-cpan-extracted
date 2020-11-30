#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TCS3472x;

my $chip = Device::Chip::TCS3472x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_ids
{
   $adapter->expect_write_then_read( "\xB2", 1 )
      ->returns( "\x44" );

   is( $chip->read_id->get, "44",
      '->read_ids yields correct chip ID' );

   $adapter->check_and_clear( '->read_ids' );
}

done_testing;
