#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SSD1306::I2C;

my $chip = Device::Chip::SSD1306::I2C->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->send_cmd
{
   $adapter->expect_write( "\x80\x01\x80\x02\x00\x03" );

   await $chip->send_cmd( 1, 2, 3 );

   $adapter->check_and_clear( '$chip->send_cmd' );
}

# ->send_data
{
   $adapter->expect_write( "\x40ABC" );

   await $chip->send_data( "ABC" );

   $adapter->check_and_clear( '$chip->send_data' );
}

done_testing;
