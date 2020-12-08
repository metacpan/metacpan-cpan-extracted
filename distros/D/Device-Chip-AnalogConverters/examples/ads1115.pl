#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::ADS1115;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;
use Time::HiRes qw( sleep );

GetOptions(
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER ),
   'mount|M=s'   => \( my $MOUNTPARAMS ),
) or exit 1;

my $chip = Device::Chip::ADS1115->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ),
   $MOUNTPARAMS,
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

await $chip->change_config(
   PGA => "4.096V",
   DR  => "32",
);

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

sleep 1;

foreach my $ch ( 0, 1 ) {
   await $chip->change_config(
      MUX => $ch,
   );

   await $chip->trigger;
   sleep 0.2;

   printf "Channel %d: %.3f\n", $ch, await $chip->read_adc_voltage;
}
