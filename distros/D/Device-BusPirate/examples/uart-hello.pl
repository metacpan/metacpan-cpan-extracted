#!/usr/bin/perl

use strict;
use warnings;

use Device::BusPirate;
use Getopt::Long;

GetOptions(
   'p|pirate=s' => \my $PIRATE,
   'b|baud=i'   => \my $BAUD,
) or exit 1;

my $pirate = Device::BusPirate->new(
   serial => $PIRATE,
   baud   => $BAUD,
);

my $uart = $pirate->enter_mode( "UART" )->get;

my $config = shift // "9600,8,n,1";
my ( $baud, $bits, $parity, $stop ) = split m/,/, $config;

$uart->configure(
   open_drain => 0,
   baud   => $baud,
   bits   => $bits,
   parity => $parity,
   stop   => $stop,
)->get;

$uart->write( "Hello, world!\n" )->get;
