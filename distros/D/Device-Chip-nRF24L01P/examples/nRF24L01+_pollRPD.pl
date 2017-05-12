#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Getopt::Long;
use Data::Dump 'pp';
use Time::HiRes qw( sleep );

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),

   'p|print-config' => \my $PRINT_CONFIG,

   'C|channel=i' => \(my $CHANNEL = 30),
) or exit 1;

my $nrf = Device::Chip::nRF24L01P->new;
$nrf->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$nrf->power(1)->get;
print "Power on\n";

if( $PRINT_CONFIG ) {
   my $config = $nrf->read_config->get;
   printf "%20s: %s\n", $_, $config->{$_} for sort keys %$config;
}

# Power-down to reconfigure
$nrf->pwr_up( 0 )->get;
$nrf->chip_enable( 0 )->get;

$nrf->change_config(
   PRIM_RX => 1,
   RF_CH => $CHANNEL,
)->get;

$nrf->clear_caches;
printf "Config:\n%s\n%s\n", pp($nrf->read_config->get), pp($nrf->read_rx_config( 0 )->get);

$nrf->pwr_up( 1 )->get;
print "PWR_UP\n";

$nrf->chip_enable( 1 )->get;
print "CE high - entered PRX mode...\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

STDOUT->autoflush(1);

while(1) {
   sleep 0.05;
   my $rpd = $nrf->rpd->get;
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
