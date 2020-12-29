#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::BME280;

my $chip = Device::Chip::BME280->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_raw
{
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->returns( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );

   is_deeply( [ await $chip->read_raw ],
      [ 342320, 523072, 25792 ],
      '->read_raw returns raw ADC values'
   );

   $adapter->check_and_clear( '->read_raw' );
}

# ->read_sensor
{
   # sensor values
   $adapter->expect_write_then_read( "\xF7", 8 )
      ->returns( "\x53\x93\x00\x7F\xB4\x00\x64\xC0" );
   # DIG_T compensation
   $adapter->expect_write_then_read( "\x88", 6 )
      ->returns( "\x1C\x6F\x27\x69\x32\x00" );
   # DIG_P compensation
   $adapter->expect_write_then_read( "\x8E", 18 )
      ->returns( "\xAA\x8E\x03\xD7\xD0\x0B\x21\x21\x83\xFF\xF9\xFF\xAC\x26\x0A\xD8\xBD\x10" );
   # DIG_H compensation is in two pieces
   $adapter->expect_write_then_read( "\xA1", 1 )
      ->returns( "\x4B" );
   $adapter->expect_write_then_read( "\xE1", 7 )
      ->returns( "\x78\x01\x00\x11\x2E\x03\x1E" );

   # Round values to 2DP to avoid floating inaccuracies
   is_deeply( [ map { sprintf "%.1f", $_ } await $chip->read_sensor ],
      [ 97032.6, 21.8, 42.7 ], # 97032.6Pa, 21.8C, 42.7%
      '->read_sensor returns converted values'
   );
}

done_testing;
