#!/usr/bin/perl

use strict;
use Lab::Instrument::HP3458A;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $hp_gpib = $ARGV[0];

print "Reading value from HP3458A at GPIB address $hp_gpib\n";

my $hp = new Lab::Instrument::HP3458A(
    connection_type => 'LinuxGPIB',
    gpib_address    => $hp_gpib,
    gpib_board      => 0,
);

my $volt = $hp->get_value();

print "Result: $volt\n";
