#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $hp_gpib = $ARGV[0];

print "Reading voltage from HP34401A at GPIB address $hp_gpib\n";

my $hp = new Lab::Instrument::HP34401A(
    connection_type => 'LinuxGPIB',
    gpib_address    => $hp_gpib,
    gpib_board      => 0,
);

my $volt = $hp->$get_voltage_dc( 10, 0.00001 );

print "Result: $volt V\n";
