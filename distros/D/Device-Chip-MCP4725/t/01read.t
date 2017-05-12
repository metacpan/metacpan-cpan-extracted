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

done_testing;
