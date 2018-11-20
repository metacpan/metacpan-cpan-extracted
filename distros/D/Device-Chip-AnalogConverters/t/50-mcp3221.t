#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::MCP3221;

my $chip = Device::Chip::MCP3221->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_adc
{
   $adapter->expect_read(2)
      ->returns( "\x01\x23" );

   is( $chip->read_adc->get, 0x0123,
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

# ->read_adc_ratio
{
   $adapter->expect_read(2)
      ->returns( "\x02\x80" );

   is( $chip->read_adc_ratio->get, 0.15625,
      '$chip->read_adc_ratio'
   );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

done_testing;
