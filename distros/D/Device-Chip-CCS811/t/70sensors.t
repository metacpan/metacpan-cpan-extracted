#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test::More;
use Test::Device::Chip::Adapter;
use Test::ExpectAndCheck::Future 0.02;  # deferred results

use Future::AsyncAwait;

use Device::Chip::CCS811;

my $chip = Device::Chip::CCS811->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my @sensors = $chip->list_sensors;

is( scalar @sensors, 2, '$chip->list_sensors returns 2 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

# eCO2 sensor
{
   my $sensor = $sensors{eCO2};

   is( $sensor->units, "ppm", 'eCO2 $sensor->units' );

   $adapter->expect_write_then_read( "\x02", 6 )
      ->returns( "\x01\xAA\x00\x05\x98\x00" );

   is( $sensor->format( scalar await $sensor->read ), "426",
      'eCO2 $sensor->read+format' );

   $adapter->check_and_clear( 'eCO2 $sensor->read' );
}

# eTVOC sensor
{
   my $sensor = $sensors{eTVOC};

   is( $sensor->units, "ppb", 'eTVOC $sensor->units' );

   $adapter->expect_write_then_read( "\x02", 6 )
      ->returns( "\x01\xAA\x00\x05\x98\x00" );

   is( $sensor->format( scalar await $sensor->read ), "5",
      'eTVOC $sensor->read+format' );

   $adapter->check_and_clear( 'eTVOC $sensor->read' );
}

# sensors concurrently
{
   $adapter->expect_write_then_read( "\x02", 6 )
      ->returns( "\x01\xAC\x00\x06\x98\x00" );

   my $fCO2 = $sensors{eCO2}->read;
   my $fTVOC = $sensors{eTVOC}->read;

   is( int await $fCO2,  428, 'eCO2 value' );
   is( int await $fTVOC, 6,   'eTVOC value' );
}

# failures are not cached
{
   $adapter->expect_write_then_read( "\x02", 6 )
      ->will_fail( "I2C read timeout\n" );

   my $fT = $sensors{eCO2}->read;
   my $fP = $sensors{eTVOC}->read;

   is( $fT->failure, "I2C read timeout\n", 'eCO2 failed' );
   is( $fP->failure, "I2C read timeout\n", 'eTVOC failed' );

   # Second attempt should succeed
   $adapter->expect_write_then_read( "\x02", 6 )
      ->returns( "\x01\xAE\x00\x07\x98\x00" );

   $fT = $sensors{eCO2}->read;
   $fP = $sensors{eTVOC}->read;

   is( int await $fT, 430, 'eCO2 value' );
   is( int await $fP, 7,   'eTVOC value' );
}

done_testing;
