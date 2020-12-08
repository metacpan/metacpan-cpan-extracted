#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::MPL3115A2;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,
   'm|minmax'       => \my $MINMAX,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::MPL3115A2->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
#   $chip and $chip->protocol->power(0)->get;
}

await $chip->check_id;

await $chip->change_config(
   OS   => 16,
);

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   await $chip->oneshot;

   printf "Pressure: %.2f kPa   Temperature: %.2f C\n",
      ( await $chip->read_pressure ) / 1000, await $chip->read_temperature;

   if( $MINMAX ) {
      printf " (min %.2f, max %.2f kPa)\n",
         ( await $chip->read_min_pressure ) / 1000, ( await $chip->read_max_pressure ) / 1000;
      printf " (min %.2f, max %.2f C)\n",
         await $chip->read_min_temperature, await $chip->read_max_temperature;
   }

   sleep $INTERVAL;
}
