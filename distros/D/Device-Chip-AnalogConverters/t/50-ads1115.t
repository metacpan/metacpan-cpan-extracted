#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::ADS1115;

my $chip = Device::Chip::ADS1115->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_config
{
   $adapter->expect_write_then_read( "\x01", 2 )
      ->returns( "\x85\x83" );

   is_deeply( $chip->read_config->get,
      {
         COMP_LAT  => '',
         COMP_MODE => "TRAD",
         COMP_POL  => "LOW",
         COMP_QUE  => "DIS",
         DR        => 128,
         MODE      => "SINGLE",
         MUX       => "0-1",
         OS        => 1,
         PGA       => "2.048V",
      },
      '$chip->read_config'
   );

   $adapter->check_and_clear( '$chip->read_config' );
}

# ->change_config
{
   $adapter->expect_write( "\x01\x87\x83" );

   $chip->change_config(
      PGA => "1.024V",
   )->get;

   $adapter->check_and_clear( '$chip->change_config' );
}

# ->trigger and ->read_adc
{
   $adapter->expect_write( "\x01\x87\x83" ); # trigger
   $adapter->expect_write_then_read( "\x00", 2 )
      ->returns( "\x12\x34" );

   $chip->trigger->get;
   is( scalar $chip->read_adc->get, 0x1234,
      '$chip->read_adc returns result' );

   $adapter->check_and_clear( '$chip->trigger and ->read_adc' );
}

# ->read_adc_voltage
{
   $adapter->expect_write_then_read( "\x00", 2 )
      ->returns( "\x7d\x00" );

   is( scalar $chip->read_adc_voltage->get, 1.000,
      '$chip->read_adc_voltage returns result' );

   $adapter->check_and_clear( '$chip->read_adc_voltage' );
}

done_testing;
