#!/usr/bin/perl

use v5.26;
use warnings;

use Device::Chip::CC1101;
use Device::Chip::Adapter;

use Future::AsyncAwait;

use Getopt::Long qw( :config no_ignore_case );
use Time::HiRes qw( sleep );

STDOUT->binmode( ":encoding(UTF-8)" );

my %MORECONFIG;

GetOptions(
   # Device::Chip options
   'adatper|A=s' => \( my $ADAPTER ),

   # script options
   'print-config|P' => \( my $PRINT_CONFIG ),
   'role|R=s' => \( my $ROLE ),

   # Radio setup
   'band|B=s'    => \( my $BAND = "868MHz" ),
   'mode|m=s'    => \( my $MODE = "GFSK-38.4kb" ),
   'channel|C=i' => \( my $CHANNEL = 1 ),
   'config=s'    => sub { $_[1] =~ m/(^.*?)=(.*)/ and $MORECONFIG{$1} = $2 },
   'pkt-length|L=i' => \( my $PKTLEN ),

   # TX options
   'count=s'      => \( my $COUNT = 1 ), # s because "inf"
   'interval|i=f' => \( my $INTERVAL = 1 ),
) or exit 1;

defined $ROLE or die "Need a --role\n";

my $chip = Device::Chip::CC1101->new;
await $chip->mount(
   Device::Chip::Adapter->new_from_description( $ADAPTER )
);

await $chip->power(1);
sleep 0.05;

$SIG{INT} = $SIG{TERM} = sub { exit };
END {
   $chip->power(0)->get if $chip;
}

await $chip->reset;

await $chip->change_config(
   band => $BAND,
   mode => $MODE,

   CHAN => $CHANNEL,

   defined $PKTLEN ? (
      LENGTH_CONFIG => "fixed",
      PACKET_LENGTH => 8,
   ) : (),

   %MORECONFIG,
);

if( $PRINT_CONFIG ) {
   my %config = await $chip->read_config;
   printf "%-20s: %s\n", $_, $config{$_} for sort keys %config;
}

await $chip->flush_fifos;

if( $ROLE eq "idle" ) {
   await $chip->idle;
   exit;
}
elsif( $ROLE eq "rx" ) {
   # Arrange for GDO0 to assert at end of packet
   await $chip->change_config(
      GDO0_CFG => "rx-fifo-or-eop",
   );

   await $chip->start_rx;

   print "Receiving...\n";

   while(1) {
      # Wait for GDO0 to indicate pkt received
      # TODO: Ideally it'd be nice to do this by a Device::Chip "wait for GPIO"
      #   ability and getting the user to connect GDO0 to one of the GPIO lines.
      sleep 0.05 and redo until ( await $chip->read_pktstatus )->{GDO0};

      my $packet = await $chip->receive;
      next unless $packet->{CRC_OK};

      printf "RX: %*v02X\n", ' ', $packet->{data};
      printf "  RSSI=% 3.1fdBm LQI=% 3d",
         $packet->{RSSI}, $packet->{LQI};

      # attempt a silly little coloured bar indicator showing RSSI and LQI
      if( -t STDOUT ) {
         # Cope with -102dBm=0  .. -25dBm=31
         my $rssi = 41 + int( $packet->{RSSI} / 2.5 );
         my $lqi  = ( 127 - $packet->{LQI} ) / 4;

         print " [";
         foreach ( 1 .. 32 ) {
            printf "\e[%d;%dm\x{2580}\e[m",
               30 + 2*( $rssi-- > 0 ),
               40 + 4*( $lqi--  > 0 );
         }
         print "]";
      }
      print "\n";
   }
}
elsif( $ROLE eq "tx" ) {
   while( $COUNT eq "inf" or $COUNT-- ) {
      await $chip->transmit( $ARGV[0] // "\x01\x23\x45\x67\x89\xab\xcd\xef" );
      print "Transmitted\n";

      sleep $INTERVAL if $COUNT;
   }
}
