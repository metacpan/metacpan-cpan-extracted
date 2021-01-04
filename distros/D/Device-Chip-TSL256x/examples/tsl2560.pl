#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::TSL256x;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long;

GetOptions(
   'i|interval=i'   => \(my $INTERVAL = 10),
   'p|print-config' => \my $PRINT_CONFIG,

   'adapter|A=s' => \my $ADAPTER,
) or exit 1;

my $chip = Device::Chip::TSL256x->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->protocol->power(1);

$SIG{INT} = $SIG{TERM} = sub { exit 1; };

END {
   $chip and $chip->protocol->power(0)->get;
}

printf "Chip ID: %02X\n", await $chip->read_id;

await $chip->power(1);
sleep 1;

if( $PRINT_CONFIG ) {
   my $config = await $chip->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

my $gain = 1;
my $smallcount;

while(1) {
   my ( $lux, $data0, $data1 ) = await $chip->read_lux;
   printf "Lux: %.2f\n", $lux;

   # See if we should switch up to high gain
   if( $gain == 1 and $data0 < 0x1000 and $data1 < 0x1000 ) {
      $smallcount++;
      if( $smallcount >= 4 ) {
         print "Switching to GAIN=16\n";
         $gain = 16;
         await $chip->change_config( GAIN => 16 );
      }
   }
   else {
      $smallcount = 0;
   }

   # See if we should switch down to low gain
   if( $gain == 16 and ( $data0 > 0x8000 or $data1 > 0x8000 ) ) {
      print "Switching to GAIN=1\n";
      $gain = 1;
      await $chip->change_config( GAIN => 1 );
   }

   sleep $INTERVAL;
}
