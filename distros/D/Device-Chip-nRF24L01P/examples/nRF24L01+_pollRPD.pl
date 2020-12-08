#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;
use Data::Dump 'pp';
use Time::HiRes qw( sleep );

GetOptions(
   'adapter|A=s' => \my $ADAPTER,

   'p|print-config' => \my $PRINT_CONFIG,

   'C|channel=i' => \(my $CHANNEL = 30),
) or exit 1;

my $nrf = Device::Chip::nRF24L01P->new;
await $nrf->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $nrf->power(1);
print "Power on\n";

if( $PRINT_CONFIG ) {
   my $config = await $nrf->read_config;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

# Power-down to reconfigure
await $nrf->pwr_up( 0 );
await $nrf->chip_enable( 0 );

await $nrf->change_config(
   PRIM_RX => 1,
   RF_CH => $CHANNEL,
);

$nrf->clear_caches;
printf "Config:\n%s\n%s\n",
   pp(await $nrf->read_config), pp(await $nrf->read_rx_config( 0 ));

await $nrf->pwr_up( 1 );
print "PWR_UP\n";

await $nrf->chip_enable( 1 );
print "CE high - entered PRX mode...\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

STDOUT->autoflush(1);

while(1) {
   sleep 0.05;
   my $rpd = await $nrf->rpd;
   print $rpd ? "X" : ".";
}

END {
   if( $nrf ) {
      $nrf->chip_enable( 0 )->get;
      $nrf->pwr_up( 0 )->get;
      $nrf->power(0)->get;
      print "Power off\n";
   }
}
