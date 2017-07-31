#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::INA219;

my $chip = Device::Chip::INA219->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_shunt_voltage
{
   $adapter->expect_write_then_read( "\x01", 2 )
      ->returns( "\x00\x7B" );

   is( $chip->read_shunt_voltage->get, 1230,
      '->read_shunt_voltage result' );

   $adapter->check_and_clear( '->read_shunt_voltage' );
}

# ->read_shunt_voltage
{
   $adapter->expect_write_then_read( "\x02", 2 )
      ->returns( "\x27\x10" );

   is( $chip->read_bus_voltage->get, 5000,
      '->read_bus_voltage result' );

   $adapter->check_and_clear( '->read_bus_voltage' );
}

done_testing;
