#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

# SHT4x has a different command structure to the other chips

use Device::Chip::SHT4x;

my $chip = Device::Chip::SHT4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->get_serial_number
{
   $adapter->expect_write_then_read( "\x89", 6 )
      ->will_done( "\x0F\x4B\xCF\x3A\x90\xE4" );

   is( await $chip->get_serial_number, "\x0F\x4B\x3A\x90",
      '->get_serial_number yields correct chip serial' );

   $adapter->check_and_clear( '->get_serial_number' );
}

done_testing;
