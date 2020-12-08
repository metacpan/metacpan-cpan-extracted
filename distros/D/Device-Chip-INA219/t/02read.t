#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::INA219;

my $chip = Device::Chip::INA219->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_shunt_voltage
{
   $adapter->expect_write_then_read( "\x01", 2 )
      ->returns( "\x00\x7B" );

   is( await $chip->read_shunt_voltage, 1230,
      '->read_shunt_voltage result' );

   $adapter->check_and_clear( '->read_shunt_voltage' );
}

# ->read_shunt_voltage
{
   $adapter->expect_write_then_read( "\x02", 2 )
      ->returns( "\x27\x10" );

   is( await $chip->read_bus_voltage, 5000,
      '->read_bus_voltage result' );

   $adapter->check_and_clear( '->read_bus_voltage' );
}

done_testing;
