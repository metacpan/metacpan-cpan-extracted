#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::MPL3115A2;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,
   'm|minmax'       => \my $MINMAX,

   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
) or exit 1;

my $chip = Device::Chip::MPL3115A2->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
#   $chip and $chip->protocol->power(0)->get;
}

$chip->check_id->get;

$chip->change_config(
   OS   => 16,
)->get;

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   $chip->oneshot->get;

   printf "Pressure: %.2f kPa   Temperature: %.2f C\n",
      $chip->read_pressure->get / 1000, $chip->read_temperature->get;

   if( $MINMAX ) {
      printf " (min %.2f, max %.2f kPa)\n",
         $chip->read_min_pressure->get / 1000, $chip->read_max_pressure->get / 1000;
      printf " (min %.2f, max %.2f C)\n",
         $chip->read_min_temperature->get, $chip->read_max_temperature->get;
   }

   sleep $INTERVAL;
}
