#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

use Device::Chip::MCP4725;

my $chip = Device::Chip::MCP4725->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->read_config
{
   $adapter->expect_read( 5 )
      ->returns( "\xC0\x80\x00\x08\x00" );

   is( await $chip->read_config,
      {
         RDY        => 1,
         POR        => 1,
         PD         => "normal",
         DAC        => 2048,
         EEPROM_PD  => "normal",
         EEPROM_DAC => 2048,
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->write_dac
{
   $adapter->expect_write( "\x04\x00" );

   await $chip->write_dac( 1024 );

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac with powerdown
{
   $adapter->expect_write( "\x24\x00" );

   await $chip->write_dac( 1024, "100k" );

   $adapter->check_and_clear( '$chip->write_dac with powerdown' );
}

# ->write_dac_and_eeprom
{
   $adapter->expect_write( "\x60\x80\x00" );

   await $chip->write_dac_and_eeprom( 2048 );

   $adapter->check_and_clear( '$chip->write_dac_and_eeprom' );
}

done_testing;
