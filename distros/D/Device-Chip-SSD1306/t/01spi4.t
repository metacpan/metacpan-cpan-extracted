#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::SSD1306::SPI4;

my $chip = Device::Chip::SSD1306::SPI4->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
   dc => "DC",
)->get;

# ->send_cmd
{
   $adapter->expect_write_gpios( { DC => 0 } );
   $adapter->expect_readwrite( "\x01\x02\x03" );

   $chip->send_cmd( 1, 2, 3 )->get;

   $adapter->check_and_clear( '$chip->send_cmd' );
}

# ->send_data
{
   $adapter->expect_write_gpios( { DC => 1 } );
   $adapter->expect_readwrite( "ABC" );

   $chip->send_data( "ABC" )->get;

   $adapter->check_and_clear( '$chip->send_data' );
}

done_testing;
