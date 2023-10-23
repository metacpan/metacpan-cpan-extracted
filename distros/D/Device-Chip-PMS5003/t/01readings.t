#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;
use Test::Device::Chip::Adapter 0.26; # ->use_read_buffer

use Future::AsyncAwait;

use Device::Chip::PMS5003;

my $chip = Device::Chip::PMS5003->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

$adapter->use_read_buffer;

# readings
{
   $chip->start;

   my $f = $chip->read_all;

   $adapter->write_read_buffer(
      "\x42\x4D\x00\x1C" . # header
      "\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x07\x00\x08\x00\x09\x00\x0A\x00\x0B\x00\x0C" . # data
      "\x00\x00" .         # reserved, zeroes
      "\x00\xF9"           # checksum
   );

   is( await $f,
      {
         concentration => {
            pm1   => 1,
            pm2_5 => 2,
            pm10  => 3,
         },
         atmos => {
            pm1   => 4,
            pm2_5 => 5,
            pm10  => 6,
         },
         particles => {
            pm0_3 => 7,
            pm0_5 => 8,
            pm1   => 9,
            pm2_5 => 10,
            pm5   => 11,
            pm10  => 12,
         },
      },
      'result of ->read_all' );

   $adapter->check_and_clear( '$chip->read_all after ->start' );
}

done_testing;
