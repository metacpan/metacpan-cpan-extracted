#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SSD1306::SPI4;

my $chip = Device::Chip::SSD1306::SPI4->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
   dc => "DC",
);

# ->send_cmd
{
   $adapter->expect_write_gpios( { DC => 0 } );
   $adapter->expect_readwrite( "\x01\x02\x03" );

   await $chip->send_cmd( 1, 2, 3 );

   $adapter->check_and_clear( '$chip->send_cmd' );
}

# ->send_data
{
   $adapter->expect_write_gpios( { DC => 1 } );
   $adapter->expect_readwrite( "ABC" );

   await $chip->send_data( "ABC" );

   $adapter->check_and_clear( '$chip->send_data' );
}

done_testing;
