#!/usr/bin/perl

use strict;
use warnings;

use Device::Chip::nRF24L01P;
use Device::Chip::Adapter;

use Getopt::Long qw( :config no_ignore_case );
use Data::Dump 'pp';
use Time::HiRes qw( sleep );

GetOptions(
   'adapter|A=s' => \( my $ADAPTER = "BusPirate" ),

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
$nrf->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
)->get;

$nrf->power(1)->get;
print "Power on\n";

# Power-down to reconfigure
$nrf->pwr_up( 0 )->get;
$nrf->chip_enable( 0 )->get;

$nrf->change_config(
   PRIM_RX => 1,
   RF_DR   => $RATE,
   RF_CH   => $CHANNEL,
   AW      => $AW,
   EN_DPL  => $DPL,
)->get;

$nrf->change_rx_config( 0,
   RX_ADDR => $ADDRESS,
   ( $DPL ?
      ( DYNPD   => 1 ) :
      ( RX_PW   => $PW ) ),
)->get;

$nrf->clear_caches;
printf "PRX config:\n%s\n%s\n", pp($nrf->read_config->get), pp($nrf->read_rx_config( 0 )->get);

printf "Listening on channel %d address %s\n",
   $nrf->read_config->get->{RF_CH}, $nrf->read_rx_config( 0 )->get->{RX_ADDR};

$nrf->flush_rx_fifo->get;

$nrf->reset_interrupt->get;

$nrf->pwr_up( 1 )->get;
print "PWR_UP\n";

$nrf->chip_enable( 1 )->get;
print "CE high - entered PRX mode...\n";

$SIG{INT} = $SIG{TERM} = sub { exit };

while(1) {
   sleep 0.05 until $nrf->read_status->get->{RX_DR};
   print "Packet received...\n";

   my $plen;
   if( $DPL ) {
      $plen = $nrf->read_rx_payload_width->get;
      print "Dynamic payload length $plen\n";
      if( !$plen or $plen > 32 ) {
         print "Invalid length; discarding\n";
         $nrf->flush_rx_fifo->get;
         $nrf->reset_interrupt->get;
         next;
      }
   }
   else {
      $plen = $PW;
   }

   my $payload = $nrf->read_rx_payload( $plen )->get;
   printf "Payload: %v.02x\n", $payload;

   $nrf->flush_rx_fifo->get;
   $nrf->reset_interrupt->get;
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
