#!/usr/bin/perl

use strict;

use Lab::Instrument;
use Lab::Instrument::PD11042;

my $motor=new Lab::Instrument::PD11042(
        connection_type=>'RS232',
        port => 'COM2',
);

unless (@ARGV > 0) {
    print "Usage: $0 target-angle\n";
    exit;
}

#my $bla=$ARGV[0];
my $angle=$ARGV[0];

print "our move is $angle\n";

$motor->move('ABS',$angle);

sleep(10);

my $pos = $motor->get_position();

print "Now at position $pos\n";
