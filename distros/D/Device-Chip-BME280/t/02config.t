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

done_testing;
