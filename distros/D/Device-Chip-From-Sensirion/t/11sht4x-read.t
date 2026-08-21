#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

my $overridden_time;
BEGIN { *CORE::GLOBAL::time = sub { return $overridden_time; } }

use Device::Chip::SHT4x;

my $chip = Device::Chip::SHT4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

sub _gen_u16_with_crc
{
   my ( $val ) = @_;
   return pack "S> C", $val, Device::Chip::From::Sensirion::_gen_crc8( pack "S>", $val );
}

# read at default (high) precision
{
   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_u16_with_crc( 0x6327 ) . _gen_u16_with_crc( 0x8E58 ) );

   is( [ await $chip->read_measurement ], [ rounded(22.78, 2), rounded(63.50, 2) ],
      '->read_measurement yields correct measurement values' );

   $adapter->check_and_clear( '->read_measurement' );
}

# read at low precision
{
   $adapter->expect_write( "\xE0" );
   $adapter->expect_sleep( 0.002 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_u16_with_crc( 0x6320 ) . _gen_u16_with_crc( 0x8E50 ) );

   await $chip->change_config( precision => "low" );

   is( [ await $chip->read_measurement ], [ rounded(22.76, 2), rounded(63.49, 2) ],
      '->read_measurement yields correct measurement values' );

   $adapter->check_and_clear( '->read_measurement at low precision' );
}

# read with heater
{
   $adapter->expect_write( "\x32" );
   $adapter->expect_sleep( 0.110 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_u16_with_crc( 0x8899 ) . _gen_u16_with_crc( 0x5544 ) );

   await $chip->change_config( heater_power => "200mW", heater_duration => "0.1s" );

   is( [ await $chip->read_measurement ], [ rounded(48.38, 2), rounded(35.63, 2) ],
      '->read_measurement yields correct measurement values' );

   $adapter->check_and_clear( '->read_measurement with heater' );
}

# read with heater on interval
{
   $overridden_time = 1000;

   sub _gen_readings {
      my ( $temp, $humid ) = @_;
      _gen_u16_with_crc( ( $temp + 45 ) / 175 * 0xFFFF ) .
      _gen_u16_with_crc( ( $humid + 6 ) / 125 * 0xFFFF )
   }

   # pre-cache a set of values first that are within the heater limits
   $adapter->expect_write( "\x32" ); # ignore this
   $adapter->expect_sleep( 0.110 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 22.78, 94.76 ) );
   await $chip->read_measurement;

   await $chip->change_config( heater_interval => 10, heater_cooldown => 3 );

   # First read should activate the heater
   $adapter->expect_write( "\x32" );
   $adapter->expect_sleep( 0.110 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 66, 22 ) );

   is( [ await $chip->read_measurement ], [ rounded(22.78, 2), rounded(94.76, 2) ],
      'first ->read_measurement with heater on interval yields cached values' );

   # A read within cooldown time should just return the cache and not measure again
   $overridden_time += 2;

   # No expectations

   is( [ await $chip->read_measurement ], [ rounded(22.78, 2), rounded(94.76, 2) ],
      'quick ->read_measurement with heater on interval yields cache' );

   # Next read should not use the heater because timer
   $overridden_time += 3;
   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 23.46, 63.02 ) );

   is( [ await $chip->read_measurement ], [ rounded(23.46, 2), rounded(63.02, 2) ],
      'second ->read_measurement with heater on interval' );

   # Next read should not use heater because below humidity
   $overridden_time += 10;
   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 82.83, 63.02 ) );

   is( [ await $chip->read_measurement ], [ rounded(82.83, 2), rounded(63.02, 2) ],
      'third ->read_measurement with heater on interval does not use heater' );

   # Next read should not use heater because above temperature
   $overridden_time += 10;
   $adapter->expect_write( "\xFD" );
   $adapter->expect_sleep( 0.010 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 40.52, 88.02 ) );

   is( [ await $chip->read_measurement ], [ rounded(40.52, 2), rounded(88.02, 2) ],
      'fourth ->read_measurement with heater on interval does not use heater' );

   # Next read should use heater because within limits
   $overridden_time += 10;
   $adapter->expect_write( "\x32" );
   $adapter->expect_sleep( 0.110 );
   $adapter->expect_read( 6 )
      ->will_done( _gen_readings( 40.52, 88.02 ) );

   is( [ await $chip->read_measurement ], [ rounded(40.52, 2), rounded(88.02, 2) ],
      'fourth ->read_measurement with heater on interval does not use heater' );
}

done_testing;
