#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::AD5691R;

my $chip = Device::Chip::AD5691R->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   # initial ->read_config uses in-memory state

   is( await $chip->read_config,
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

   await $chip->change_config(
      GAIN => 2,
   );

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->write_dac
{
   $adapter->expect_write( "\x10\x4D\x20" );

   await $chip->write_dac( 1234 );

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac_voltage
{
   $adapter->expect_write( "\x30\x3E\xF0" );

   await $chip->write_dac_voltage( 1.23 );

   $adapter->check_and_clear( '$chip->write_dac_voltage' );
}

done_testing;
