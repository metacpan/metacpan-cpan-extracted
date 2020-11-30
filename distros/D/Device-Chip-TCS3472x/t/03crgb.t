#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::TCS3472x;

my $chip = Device::Chip::TCS3472x->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_crgb
{
   $adapter->expect_write_then_read( "\xB4", 8 )
      ->returns( "\x2B\x01\x90\x00\x64\x00\x35\x00" );

   is_deeply( [ $chip->read_crgb->get ],
      [ 299, 144, 100, 53 ],
      '->read_crgb yields cRGB values'
   );

   $adapter->check_and_clear( '->read_crgb' );
}

done_testing;
