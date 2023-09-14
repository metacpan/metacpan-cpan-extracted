#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::INA219;

my $chip = Device::Chip::INA219->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_write_then_read( "\x00", 2 )
      ->returns( "\x39\x9F" );

   is( await $chip->read_config,
      {
         RST  => '',
         BRNG => "32V",
         PG   => "320mV",
         BADC => "12b",
         SADC => "12b",
         MODE_CONT  => 1,
         MODE_BUS   => 1,
         MODE_SHUNT => 1,
      },
      '->read_config returns config' );

   $adapter->check_and_clear( '->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x00\x3D\x57" );

   await $chip->change_config(
      BADC => 4,
      SADC => 4,
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

done_testing;
