#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter;

use Future::AsyncAwait;

# All chips share this method so we'll just pick one

use Device::Chip::SCD4x;

my $chip = Device::Chip::SCD4x->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

# ->get_serial_number
{
   $adapter->expect_write_then_read( "\x36\x82", 9 )
      ->will_done( "\xF8\x96\x31\x9F\x07\xC2\x3B\xBE\x89" );

   is( await $chip->get_serial_number, "\xF8\x96\x9F\x07\x3B\xBE",
      '->get_serial_number yields correct chip serial' );

   $adapter->check_and_clear( '->get_serial_number' );
}

# Check CRC failure
{
   $adapter->expect_write_then_read( "\x36\x82", 9 )
      #                               v-- wrong byte
      ->will_done( "\xF8\x96\x31\x9F\x87\xC2\x3B\xBE\x89" );

   is( dies { $chip->get_serial_number->get }, "CRC mismatch on word 1\n",
      '->get_serial_number yields correct chip serial' );

   $adapter->check_and_clear( '->get_serial_number' );
}

done_testing;
