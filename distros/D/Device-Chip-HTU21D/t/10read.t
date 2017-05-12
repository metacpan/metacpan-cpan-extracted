#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::HTU21D;

my $chip = Device::Chip::HTU21D->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_temperature - replies immediately
{
   $adapter->expect_write( "\xF3" );
   $adapter->expect_read( 2 )
      ->returns( "\x5A\x2C" );

   is( int( $chip->read_temperature->get ), 15,
       '$chip->read_temperature' );

   $adapter->check_and_clear( '$chip->read_temperature' );
}

# ->read_temperature delay until ready
{
   $adapter->expect_write( "\xF3" );
   $adapter->expect_read( 2 )
      ->fails( "NACK" );
   $adapter->expect_sleep( "0.01" );
   $adapter->expect_read( 2 )
      ->returns( "\x5D\x20" );

   is( int( $chip->read_temperature->get ), 17,
       '$chip->read_temperature delayed' );

   $adapter->check_and_clear( '$chip->read_temperature delayed' );
}

# ->read_humidity
{
   $adapter->expect_write( "\xF5" );
   $adapter->expect_read( 2 )
      ->returns( "\x5A\x2C" );

   is( int( $chip->read_humidity->get ), 38,
       '$chip->read_humidity' );

   $adapter->check_and_clear( '$chip->read_humidity' );
}

done_testing;
