#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MCP4725;

my $chip = Device::Chip::MCP4725->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   $adapter->expect_read( 5 )
      ->returns( "\xC0\x80\x00\x08\x00" );

   is_deeply( $chip->read_config->get,
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

   $chip->write_dac( 1024 )->get;

   $adapter->check_and_clear( '$chip->write_dac' );
}

# ->write_dac with powerdown
{
   $adapter->expect_write( "\x24\x00" );

   $chip->write_dac( 1024, "100k" )->get;

   $adapter->check_and_clear( '$chip->write_dac with powerdown' );
}

# ->write_dac_and_eeprom
{
   $adapter->expect_write( "\x60\x80\x00" );

   $chip->write_dac_and_eeprom( 2048 )->get;

   $adapter->check_and_clear( '$chip->write_dac_and_eeprom' );
}

done_testing;
