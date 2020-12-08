#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Future::AsyncAwait;
use Getopt::Long qw( :config no_ignore_case );
use Data::Dump 'pp';
use Time::HiRes qw( sleep );

GetOptions(
   'adapter|A=s' => my $ADAPTER,

   'a|address=s' => \my $ADDRESS,
   'C|channel=i' => \(my $CHANNEL = 30),
   'r|rate=s'    => \(my $RATE = "2M"),
   'D|dpl'       => \(my $DPL = 0),
   'W|width=i'   => \(my $PW = 1),
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
   PRIM_RX => 1,
   RF_DR   => $RATE,
   RF_CH   => $CHANNEL,
   AW      => $AW,
   EN_DPL  => $DPL,
);

await $nrf->change_rx_config( 0,
   RX_ADDR => $ADDRESS,
   ( $DPL ?
      ( DYNPD   => 1 ) :
      ( RX_PW   => $PW ) ),
);

$nrf->clear_caches;
printf "PRX config:\n%s\n%s\n",
   pp(await $nrf->read_config), pp(await $nrf->read_rx_config( 0 ));

printf "Listening on channel %d address %s\n",
   ( await $nrf->read_config )->{RF_CH}, ( await $nrf->read_rx_config( 0 ) )->{RX_ADDR};

await $nrf->flush_rx_fifo;

await $nrf->reset_interrupt;

await $nrf->pwr_up( 1 );
print "PWR_UP\n";

await $nrf->chip_enable( 1 );
print "CE high - entered PRX mode...\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

while(1) {
   sleep 0.05 until ( await $nrf->read_status )->{RX_DR};
   print "Packet received...\n";

   my $plen;
   if( $DPL ) {
      $plen = await $nrf->read_rx_payload_width;
      print "Dynamic payload length $plen\n";
      if( !$plen or $plen > 32 ) {
         print "Invalid length; discarding\n";
         await $nrf->flush_rx_fifo;
         await $nrf->reset_interrupt;
         next;
      }
   }
   else {
      $plen = $PW;
   }

   my $payload = await $nrf->read_rx_payload( $plen );
   printf "Payload: %v.02x\n", $payload;

   await $nrf->flush_rx_fifo;
   await $nrf->reset_interrupt;
}

END {
   if( $nrf ) {
      print "END\n";
      $nrf->chip_enable( 0 )->get;
      $nrf->pwr_up( 0 )->get;
      $nrf->power(0)->get;
      print "Power off\n";
   }
}
