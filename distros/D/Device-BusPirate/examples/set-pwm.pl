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

my $bb = $pirate->enter_mode( "BB" )->get;

$bb->set_pwm( freq => shift @ARGV, duty => shift @ARGV )->get;
