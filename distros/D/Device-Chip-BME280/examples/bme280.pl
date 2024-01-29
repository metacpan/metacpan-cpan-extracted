#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::BME280;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Future::IO;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,
   'addr|a=s'       => \my $ADDR,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::BME280->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   addr => $ADDR,
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

printf "Chip ID: %02X\n", await $chip->read_id;

await $chip->change_config(
   # Turn on all three sensors
   OSRS_H => 4,
   OSRS_P => 4,
   OSRS_T => 4,

   # Wake up
   MODE => "NORMAL",
);

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   my ( $press, $temp, $hum ) = await $chip->read_sensor;

   printf "Temperature=%.2fC  ", $temp;

   printf "Pressure=%.3fkPa  ", $press / 1000;

   printf "Humidity=%.2f%%\n", $hum;

   await Future::IO->sleep( $INTERVAL );
}
