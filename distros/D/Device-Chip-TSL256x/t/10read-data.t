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
   $adapter->expect_write_then_read( "\x8C", 2 )
      ->returns( "\x34\x12" );

   is( $chip->read_data0->get, 0x1234,
      '->read_data0 returns data' );

   $adapter->check_and_clear( '$chip->read_data0' );
}

{
   $adapter->expect_write_then_read( "\x8E", 2 )
      ->returns( "\x78\x56" );

   is( $chip->read_data1->get, 0x5678,
      '->read_data1 returns data' );

   $adapter->check_and_clear( '$chip->read_data1' );
}

{
   $adapter->expect_write_then_read( "\x8C", 4 )
      ->returns( "\x34\x12\x78\x56" );

   is_deeply( [ $chip->read_data->get ],
              [ 0x1234, 0x5678 ],
      '->read_data returns data' );

   $adapter->check_and_clear( '$chip->read_data' );
}

done_testing;
