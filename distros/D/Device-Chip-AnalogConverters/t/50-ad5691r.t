#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::AD5691R;

my $chip = Device::Chip::AD5691R->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   # initial ->read_config uses in-memory state

   is_deeply( $chip->read_config->get,
      {
         GAIN => 1,
         PD   => "normal",
         REF  => 1,
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x40\x08\x00" );

   $chip->change_config(
      GAIN => 2,
   )->get;

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->write_dac
{
   $adapter->expect_write( "\x10\x4D\x20" );

   $chip->write_dac( 1234 )->get;

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac_voltage
{
   $adapter->expect_write( "\x30\x3E\xF0" );

   $chip->write_dac_voltage( 1.23 )->get;

   $adapter->check_and_clear( '$chip->write_dac_voltage' );
}

done_testing;
