#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter 0.14;

use Device::Chip::MAX1166x;

my $chip = Device::Chip::MAX1166x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_adc
{
   $adapter->expect_read(2)
      ->returns( "\x04\x8C" );

   is( $chip->read_adc->get, 0x048C,
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

# ->read_adc_ratio
{
   $adapter->expect_read(2)
      ->returns( "\x0A\x00" );

   is( $chip->read_adc_ratio->get, 0.15625,
      '$chip->read_adc_ratio'
   );

   $adapter->check_and_clear( '$chip->read_adc_ratio' );
}

done_testing;
