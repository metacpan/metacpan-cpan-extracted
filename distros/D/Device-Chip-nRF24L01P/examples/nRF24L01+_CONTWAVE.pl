#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long;
use Data::Dump 'pp';

GetOptions(
   'adapter|A=s' => \my $ADAPTER,

   'C|channel=i' => \(my $CHANNEL = 30),
) or exit 1;

my $nrf = Device::Chip::nRF24L01P->new;
await $nrf->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $nrf->power(1);
print "Power on\n";

# Power-down to reconfigure
await $nrf->pwr_up( 0 );
await $nrf->chip_enable( 0 );

await $nrf->change_config(
   PRIM_RX => 0,
   RF_CH => $CHANNEL,
   LOCK_PLL => 1,
   CONT_WAVE => 1,
);

$nrf->clear_caches;
printf "Config:\n%s\n%s\n",
   pp(await $nrf->read_config), pp(await $nrf->read_rx_config( 0 ));

await $nrf->pwr_up( 1 );
print "PWR_UP\n";

await $nrf->chip_enable( 1 );
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
