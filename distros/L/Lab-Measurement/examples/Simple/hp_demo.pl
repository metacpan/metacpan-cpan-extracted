#!/usr/bin/perl

use strict;
use Lab::Instrument::HP34401A;

################################

unless ( @ARGV > 0 ) {
    print "Usage: $0 GPIB-address\n";
    exit;
}

my $hp_gpib = $ARGV[0];

my $hp = new Lab::Instrument::HP34401A(
    connection_type => 'LinuxGPIB',
    gpib_address    => $hp_gpib,
    gpib_board      => 0,
);

$hp->beep();
$hp->scroll_message();
$hp->beep();
