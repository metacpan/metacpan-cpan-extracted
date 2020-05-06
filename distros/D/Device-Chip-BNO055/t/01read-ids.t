#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::BNO055;

my $chip = Device::Chip::BNO055->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_ids
{
   $adapter->expect_write_then_read( "\x00", 4 )
      ->returns( "\xA0\xFB\x32\x0F" );

   is( $chip->read_ids->get, "A0FB320F",
      '->read_ids yields correct chip ID' );

   $adapter->check_and_clear( '->read_ids' );
}

done_testing;
