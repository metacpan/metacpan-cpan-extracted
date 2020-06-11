#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Device::Chip::Adapter;

# writes operate directly over UART so this is the easiest to unit test
use Device::Chip::NoritakeGU_D;

my $chip = Device::Chip::NoritakeGU_D->new( interface => "UART" );

$chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
)->get;

{
   $adapter->expect_write( "\x1F\x28\x66\x11\x03\x00\x02\x00\x01" .
      "\x01\x80\x20\x04\xFF\xFF" );

   $chip->realtime_image_display_columns(
      "\x01\x80",
      "\x20\x04",
      "\xFF\xFF",
   )->get;

   $adapter->check_and_clear( '$chip->realtime_image_display_columns' );
}

done_testing;
