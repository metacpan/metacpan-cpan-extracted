#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::TSL256x;
use Device::Chip::Adapter;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),
) or exit 1;

my $chip = Device::Chip::TSL256x->new;
$chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$chip->protocol->power(1)->get;

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

printf "Chip ID: %02X\n", $chip->read_id->get;

$chip->power(1)->get;
sleep 1;

if( $PRINT_CONFIG ) {
   my $config = $chip->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my $gain = 1;
my $smallcount;

while(1) {
   my ( $lux, $data0, $data1 ) = $chip->read_lux->get;
   printf "Lux: %.2f\n", $lux;

   # See if we should switch up to high gain
   if( $gain == 1 and $data0 < 0x1000 and $data1 < 0x1000 ) {
      $smallcount++;
      if( $smallcount >= 4 ) {
         print "Switching to GAIN=16\n";
         $gain = 16;
         $chip->change_config( GAIN => 16 )->get;
      }
   }
   else {
      $smallcount = 0;
   }

   # See if we should switch down to low gain
   if( $gain == 16 and ( $data0 > 0xff00 or $data1 > 0xff00 ) ) {
      print "Switching to GAIN=1\n";
      $gain = 1;
      $chip->change_config( GAIN => 1 )->get;
   }

   sleep $INTERVAL;
}
