#!/usr/bin/perl

use v5.34;
use warnings;
use experimental 'signatures';

use Getopt::Long;

use Device::Serial::SLuRM;

GetOptions(
   'device|d=s' => \( my $DEVICE = "/dev/ttyUSB0" ),
   'baud|b=i'   => \my $BAUD,
) or exit 1;

my $slurm = Device::Serial::SLuRM->new(
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

$slurm->run(
   on_notify => sub {
      my ( $payload ) = @_;

      if( length $payload > 16 ) {
         my @chunks = $payload =~ m/(.{1,16})/sg;
         print("NOTIFY: "), print_hexdump($_, 16), print "\n" for shift @chunks;
         print("        "), print_hexdump($_, 16), print "\n" for @chunks;
      }
      else {
         print("NOTIFY: "), print_hexdump($_),     print "\n" for $payload;
      }
   },
)->await;
