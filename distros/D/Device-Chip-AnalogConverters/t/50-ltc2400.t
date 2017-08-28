#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

use Device::Chip::LTC2400;

my $chip = Device::Chip::LTC2400->new;

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

# ->read_adc
{
   $adapter->expect_readwrite( "\x00\x00\x00\x00" )
      ->returns( "\x20\x12\x34\x50" );

   is_deeply( $chip->read_adc->get,
      {
         EOC => 1,
         EXR => '',
         SIG => 1,
         VALUE => 0x012345,
      },
      '$chip->read_adc'
   );

   $adapter->check_and_clear( '$chip->read_adc' );
}

done_testing;
