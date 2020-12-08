#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::HTU21D;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::HTU21D->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   my $temp = await $chip->read_temperature;
   printf "Temperature: %.2fC\n", $temp;

   my $humid = await $chip->read_humidity;
   printf "Humidity:    %.1f%%\n", $humid;

   sleep $INTERVAL;
}
