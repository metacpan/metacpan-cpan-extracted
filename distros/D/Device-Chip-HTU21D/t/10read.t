#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::HTU21D;

my $chip = Device::Chip::HTU21D->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_temperature - replies immediately
{
   $adapter->expect_write( "\xF3" );
   $adapter->expect_read( 2 )
      ->returns( "\x5A\x2C" );

   is( int( await $chip->read_temperature ), 15,
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

   is( int( await $chip->read_temperature ), 17,
       '$chip->read_temperature delayed' );

   $adapter->check_and_clear( '$chip->read_temperature delayed' );
}

# ->read_humidity
{
   $adapter->expect_write( "\xF5" );
   $adapter->expect_read( 2 )
      ->returns( "\x5A\x2C" );

   is( int( await $chip->read_humidity ), 38,
       '$chip->read_humidity' );

   $adapter->check_and_clear( '$chip->read_humidity' );
}

done_testing;
