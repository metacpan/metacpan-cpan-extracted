#!/usr/bin/perl

use v5.26;
use warnings;

use utf8;

use Test2::V0;
use Test::Device::Chip::Adapter 0.13; # for UART protocol

use Future::AsyncAwait;

use Device::Chip::PMS5003;

my $chip = Device::Chip::PMS5003->new;

await $chip->mount(
   my $adapter = Test::Device::Chip::Adapter->new,
);

$adapter->use_read_buffer;

my @sensors = $chip->list_sensors;

is( scalar @sensors, 3, '$chip->list_sensors returns 3 sensors' );

# Don't rely on order
my %sensors = map { $_->name => $_ } @sensors;

{
   await $chip->initialize_sensors;
}

# sensor reading
{
   my $sensor = $sensors{pm1};

   my $f = $sensor->read;

   $adapter->write_read_buffer(
      "\x42\x4D\x00\x1C" . # header
      "\x00\x01\x00\x02\x00\x03\x00\x04\x00\x05\x00\x06\x00\x07\x00\x08\x00\x09\x00\x0A\x00\x0B\x00\x0C" . # data
      "\x00\x00" .         # reserved, zeroes
      "\x00\xF9"           # checksum
   );

   is( $sensor->format( scalar await $f ), "1",
      'pm1 $sensor->read+format' );

   $adapter->check_and_clear( 'pm1 $sensor->read' );
}

done_testing;
