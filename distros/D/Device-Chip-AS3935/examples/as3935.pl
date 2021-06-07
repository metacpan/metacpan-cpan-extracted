#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::AS3935;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 2),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::AS3935->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

await $chip->reset;

while( @ARGV ) {
   my ( $name, $value ) = ( shift @ARGV ) =~ m/^(.*?)=(.*)$/ or next;
   await $chip->change_config( $name => $value );
}

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

await $chip->calibrate_rco;

my $status = await $chip->read_calib_status;
print "  $_ => $status->{$_}\n" for sort keys %$status;

while(1) {
   my $int = await $chip->read_int;
   print "Int: NH=$int->{INT_NH} D=$int->{INT_D} L=$int->{INT_L}\n";

   if( $int->{INT_L} ) {
      my $distance = await $chip->read_distance;
      print "Distance: $distance\n";
   }

   sleep $INTERVAL;
}
