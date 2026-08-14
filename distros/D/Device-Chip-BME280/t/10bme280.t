#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BME280;

my $chip = Device::Chip::BME280->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_id
{
   $adapter->expect_write_then_read( "\xD0", 1 )
      ->will_done( "\x60" );

   is( await $chip->read_id, 0x60,
      '->read_id yields correct chip ID' );

   $adapter->check_and_clear( '->read_id' );
}

# ->check_id
{
   $adapter->expect_write_then_read( "\xD0", 1 )
      ->will_done( "\x60" );

   ok( !dies { $chip->check_id->get },
      '->check_id on correct chip ID' );

   $adapter->expect_write_then_read( "\xD0", 1 )
      ->will_done( "\x33" );

   is( dies { $chip->check_id->get },
      "ID check failed: Got 0x33, expected 0x60\n",
      '->check_id on incorrect chip ID' );

   $adapter->expect_write_then_read( "\xD0", 1 )
      ->will_done( "\x58" );

   is( dies { $chip->check_id->get },
      "ID check failed: Got 0x58, expected 0x60 (maybe this is BMP280?)\n",
      '->check_id on incorrect chip ID' );

   $adapter->check_and_clear( '->check_id' );
}

# ->read_config
{
   $adapter->expect_write_then_read( "\xF2", 4 )
      ->will_done( "\x00\x00\x00\x00" );

   is( await $chip->read_config,
      {
         FILTER   => "OFF",
         MODE     => "SLEEP",
         OSRS_H   => "SKIP",
         OSRS_P   => "SKIP",
         OSRS_T   => "SKIP",
         SPI3W_EN => '',
         T_SB     => 0.5,
      },
      '->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   await $chip->read_config;

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\xF2\x03" );
   $adapter->expect_write( "\xF4\x6C" );

   await $chip->change_config(
      OSRS_H => 4,
      OSRS_P => 4,
      OSRS_T => 4,
   );

   # subsequent read does not talk to chip a second time but yields new values
   is( await $chip->read_config,
      {
         FILTER   => "OFF",
         MODE     => "SLEEP",
         OSRS_H   => 4,
         OSRS_P   => 4,
         OSRS_T   => 4,
         SPI3W_EN => '',
         T_SB     => 0.5,
      },
      '$chip->read_config returns new config after ->change_config'
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->read_raw
{
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );

   is( [ await $chip->read_raw ],
      [ 342320, 523072, 25792 ],
      '->read_raw returns raw ADC values'
   );

   $adapter->check_and_clear( '->read_raw' );
}

# ->read_sensor
{
   # sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->will_done( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );
   # DIG_T compensation
   $adapter->expect_write_then_read( "\x88", 6 )
      ->will_done( "\x1C\x6F\x27\x69\x32\x00" );
   # DIG_P compensation
   $adapter->expect_write_then_read( "\x8E", 18 )
      ->will_done( "\xAA\x8E\x03\xD7\xD0\x0B\x21\x21\x83\xFF\xF9\xFF\xAC\x26\x0A\xD8\xBD\x10" );
   # DIG_H compensation is in two pieces
   $adapter->expect_write_then_read( "\xA1", 1 )
      ->will_done( "\x4B" );
   $adapter->expect_write_then_read( "\xE1", 7 )
      ->will_done( "\x78\x01\x00\x11\x2E\x03\x1E" );

   # Round values to 2DP to avoid floating inaccuracies
   is( [ map { sprintf "%.1f", $_ } await $chip->read_sensor ],
      [ 97032.6, 21.8, 42.7 ], # 97032.6Pa, 21.8C, 42.7%
      '->read_sensor returns converted values'
   );

   $adapter->check_and_clear( '->read_sensor' );
}

done_testing;
