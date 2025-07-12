#!/usr/bin/perl

use v5.36;

use Future::AsyncAwait;

use Device::Serial::SLuRM;
use Device::Serial::MSLuRM;
use Future;
use Future::IO 0.16; # ->load_impl
use Future::Selector;
use Getopt::Long;
use POSIX qw( strftime );
use Time::HiRes qw( gettimeofday );

Future::IO->load_impl(qw( Glib UV IOAsync ));

GetOptions(
   'device|d=s' => \( my $DEVICE = "/dev/ttyUSB0" ),
   'baud|b=i'   => \my $BAUD,
   'multi'      => \my $MULTI,
) or exit 1;

my $slurm = ( $MULTI ? "Device::Serial::MSLuRM" : "Device::Serial::SLuRM" )->new(
   dev  => $DEVICE,
   baud => $BAUD,
);

sub print_hexdump ( $bytes, $width = length $bytes )
{
   my @bytes = split //, $bytes;

   print join " ", map { sprintf "%v02X", $_ } @bytes;
   print "   " x ( $width - @bytes );
   print " | ";
   print join "", map { $_ ge "\x20" && $_ lt "\x7F" ? $_ : "." } @bytes;
}

my @PKTTYPES = qw(
   META NOTIFY . REQUEST . . . .
   . . . RESPONSE ACK ERR .
);

while( my @pkt = await $slurm->recv_packet ) {
   my $now = [gettimeofday];

   my $pktctrl = shift @pkt;
   my $addr    = $MULTI ? shift @pkt : undef;
   my $payload = shift @pkt;

   my $seqno = $pktctrl & 0x0F;
   $pktctrl &= 0xF0;

   my $timestamp = sprintf( "%s.%06d", strftime("%H:%M:%S", localtime $now->[0]), $now->[1] );

   my $pkttype = $PKTTYPES[$pktctrl >> 4];
   $pkttype = sprintf("UNKNOWN-%02X", $pktctrl) if $pkttype eq ".";

   my $tofrom = $MULTI ?
      sprintf( " %s %02X", $addr & 0x80 ? "to" : "from", $addr & 0x7F ) :
      "";

   my $len = length $payload;

   printf "[%s] %s(%d)%s: %d bytes\n", $timestamp, $pkttype, $seqno, $tofrom, $len;
   if( $len > 16 ) {
      my @chunks = $payload =~ m/(.{1,16})/sg;
      print("  "), print_hexdump($_, 16), print "\n" for @chunks;
   }
   elsif( $len ) {
      print("  "), print_hexdump($_, 16), print "\n" for $payload;
   }
}
