#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::HTU21D;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
) or exit 1;

my $chip = Device::Chip::HTU21D->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my $gain = 1;
my $smallcount;

while(1) {
   my $temp = $chip->read_temperature->get;
   printf "Temperature: %.2fC\n", $temp;

   my $humid = $chip->read_humidity->get;
   printf "Humidity:    %.1f%%\n", $humid;

   sleep $INTERVAL;
}
