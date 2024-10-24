#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::SCD4x;

my $chip = Device::Chip::SCD4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x23\x18", 3 )
      ->will_done( "\x09\x12\x63" );
   $adapter->expect_write_then_read( "\x23\x22", 3 )
      ->will_done( "\x04\x4C\x42" );
   $adapter->expect_write_then_read( "\xE0\x00", 3 )
      # Example in data sheet has bad CRC here; CRC0 should be 0x42, not 0x6B
      ->will_done( "\x03\xDB\x42" );

   is( await $chip->read_config,
      {
         temperature_offset => rounded(6.2, 2),
         sensor_altitude    => 1100,
         ambient_pressure   => 98700,
      },
      '->read_config returns config'
   );

   # subsequent read does not talk to chip a second time
   await $chip->read_config;

   $adapter->check_and_clear( '->read_config' );
}

done_testing;
