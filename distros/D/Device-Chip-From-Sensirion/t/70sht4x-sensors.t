#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter;
use Test::ExpectAndCheck::Future 0.02;  # deferred results

use Future::AsyncAwait;

use Device::Chip::SHT4x;

my $chip = Device::Chip::SHT4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

my @sensors = $chip->list_sensors;

is( scalar @sensors, 2, '$chip->list_sensors returns 2 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

sub _gen_u16_with_crc
{
   my ( $val ) = @_;
   return pack "S> C", $val, Device::Chip::From::Sensirion::_gen_crc8( pack "S>", $val );
}
sub _gen_readings
{
   my ( $temp, $humid ) = @_;
   _gen_u16_with_crc( ( $temp + 45 ) / 175 * 0xFFFF ) .
   _gen_u16_with_crc( ( $humid + 6 ) / 125 * 0xFFFF )
}

# temperature sensor
{
   my $sensor = $sensors{temperature};

   is( $sensor->units, "°C", 'temperature $sensor->units' );

   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 25, 37 ) );

   is( $sensor->format( scalar await $sensor->read ), "25.00",
      'temperature $sensor->read+format' );

   $adapter->check_and_clear( 'temperature $sensor->read' );
}

# humidity sensor
{
   my $sensor = $sensors{humidity};

   is( $sensor->units, "%RH", 'humidity $sensor->units' );

   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 25, 37 ) );

   is( $sensor->format( scalar await $sensor->read ), "37.00",
      'humidity $sensor->read+format' );

   $adapter->check_and_clear( 'humidity $sensor->read' );
}

done_testing;
