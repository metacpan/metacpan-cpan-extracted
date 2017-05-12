#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::SSD1306::I2C;

my $chip = Device::Chip::SSD1306::I2C->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->send_cmd
{
   $adapter->expect_write( "\x80\x01\x80\x02\x00\x03" );

   $chip->send_cmd( 1, 2, 3 )->get;

   $adapter->check_and_clear( '$chip->send_cmd' );
}

# ->send_data
{
   $adapter->expect_write( "\x40ABC" );

   $chip->send_data( "ABC" )->get;

   $adapter->check_and_clear( '$chip->send_data' );
}

done_testing;
