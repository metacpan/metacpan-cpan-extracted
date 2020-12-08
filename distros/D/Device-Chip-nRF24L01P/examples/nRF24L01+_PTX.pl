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

   'a|address=s' => \my $ADDRESS,
   'C|channel=i' => \(my $CHANNEL = 30),
   'r|rate=s'    => \(my $RATE = "2M"),
   'D|dpl'       => \(my $DPL = 0),

   'c|count=i'   => \(my $COUNT = 1),
) or exit 1;

my $AW = scalar( split m/:/, $ADDRESS );
$AW >= 3 and $AW <= 5 or die "Invalid address - must be 3 to 5 octets\n";

$RATE =~ s/M$/000000/i;
$RATE =~ s/k$/000/i;

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
   RF_DR   => $RATE,
   RF_CH   => $CHANNEL,
   ARD     => 1500,   # 1500usec retransmit delay
   ARC     => 9,
   AW      => $AW,
   TX_ADDR => $ADDRESS,
   EN_DPL  => $DPL,
);

# We need to set pipe 0's RX ADDR to equal TX ADDR so we receive the auto-ack
await $nrf->change_rx_config( 0,
   RX_ADDR => $ADDRESS,
   ( $DPL ?
      ( DYNPD   => 1 ) :
      () ),
);

$nrf->clear_caches;
printf "PTX config:\n%s\n%s\n",
   pp(await $nrf->read_config), pp(await $nrf->read_rx_config( 0 ));

printf "Transmitting on channel %d address %s\n",
   @{ await $nrf->read_config }{qw( RF_CH TX_ADDR )};

await $nrf->flush_tx_fifo;

await $nrf->reset_interrupt;

await $nrf->pwr_up( 1 );
print "PWR_UP\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

while( $COUNT == -1 or ( $COUNT--) > 0 ) {
   await $nrf->write_tx_payload( "X" );
   await $nrf->chip_enable( 1 );
   print "CE high - entered PTX mode...\n";

   my $status;
   1 while $status = await $nrf->read_status and
      not ( $status->{TX_DS} || $status->{MAX_RT} );

   await $nrf->chip_enable( 0 );

   if( $status->{MAX_RT} ) {
      print STDERR "MAX_RT exceeded; packet lost\n";
      printf "Observe TX: %s\n", pp(await $nrf->observe_tx_counts);
   }
   else {
      print "Packet sent\n";
   }

   await $nrf->reset_interrupt;

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
