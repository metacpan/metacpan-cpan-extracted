#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Getopt::Long;
use Data::Dump 'pp';

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),

   'C|channel=i' => \(my $CHANNEL = 30),
) or exit 1;

my $nrf = Device::Chip::nRF24L01P->new;
$nrf->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$nrf->power(1)->get;
print "Power on\n";

# Power-down to reconfigure
$nrf->pwr_up( 0 )->get;
$nrf->chip_enable( 0 )->get;

$nrf->change_config(
   PRIM_RX => 0,
   RF_CH => $CHANNEL,
   LOCK_PLL => 1,
   CONT_WAVE => 1,
)->get;

$nrf->clear_caches;
printf "Config:\n%s\n%s\n", pp($nrf->read_config->get), pp($nrf->read_rx_config( 0 )->get);

$nrf->pwr_up( 1 )->get;
print "PWR_UP\n";

$nrf->chip_enable( 1 )->get;
print "CE high - entered PTX mode...\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

STDOUT->autoflush(1);

while(1) {
   print "Emitting CONT_WAVE; SIGINT to stop\n";
   sleep 1;
}

END {
   if( $nrf ) {
      $nrf->chip_enable( 0 )->get;
      $nrf->pwr_up( 0 )->get;
      $nrf->power(0)->get;
      print "Power off\n";
   }
}
