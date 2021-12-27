#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::Adapter;
use Device::Chip::CCS811;

use Future::AsyncAwait;

use Getopt::Long;
use Time::HiRes qw( sleep );

use Data::Dump 'pp';

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 1),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
   'mount|M=s'   => \my $MOUNTPARAMS,
) or exit 1;

my $chip = Device::Chip::CCS811->new;
await $chip->mount_from_paramstr(
   Device::Chip::Adapter->new_from_description( $ADAPTER ), $MOUNTPARAMS,
);

await $chip->protocol->power(0);

await $chip->protocol->power(1);
END { $chip and $chip->protocol->power(0)->get; }

( await $chip->read_id ) == 0x81 or
   die "Chip ID does not match CCS811 signature\n";

await $chip->init;

# Set any other config changes
while( @ARGV ) {
   my ( $name, $value ) = ( shift @ARGV ) =~ m/^(.*?)=(.*)$/ or next;
   await $chip->change_config( $name => $value );
}

my $config = await $chip->read_config;
if( $PRINT_CONFIG ) {
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

while(1) {
   my $readings = await $chip->read_alg_result_data;
   printf "eCO2 % 5dppm eTVOC % 5dppb\n", $readings->{eCO2}, $readings->{eTVOC};

   sleep $INTERVAL;
}
