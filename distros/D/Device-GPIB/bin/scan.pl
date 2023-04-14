#!/usr/bin/perl
#
# scan.pl
#
# Scan the GPIB bus for devices and print the address and ID of each one founf

use strict;
use Device::GPIB::Controller;
use Device::GPIB::Generic;

use Getopt::Long;

my @options = 
    (
     'h',                   # Help, show usage
     'port=s',              # port[:baud:databits:parity:stopbits:handshake]
     'debug',               # Show debugging info like bytes in and out
     'verbose',             # Print progress
     'start=n',             # Start address default 0
     'end=n',               # end address default 30
    );

&GetOptions(@options) || &usage;
&usage if $main::opt_h;
my $port = '/dev/ttyUSB0';
my $verbose = 0;
my $start = 1;
my $end = 30;

$verbose = $main::opt_verbose if defined $main::opt_verbose;
$port = $main::opt_port if defined $main::opt_port;
$start = $main::opt_start if defined $main::opt_start;
$end = $main::opt_end if defined $main::opt_end;
$Device::GPIB::Controller::debug = 1 if $main::opt_debug;

die "Start address is after end address" unless $start <= $end;

my $d = Device::GPIB::Controller->new($port);
exit unless $d;

my $gpib = Device::GPIB::Generic->new($d, 0);
die "Could not open GPIB" unless $gpib;

for (my $address = $start; $address <= $end; $address++)
{
    print "Trying GPIB $address\n" if $verbose;
    $gpib->setAddress($address);
    my $id = $gpib->sendAndRead('ID?');
    next unless defined $id;
    print "$address: $id\n";
}

sub usage
{
    print "usage: $0 [-h]
          [-port [Prologix:[port[:baud:databits:parity:stopbits:handshake]]] 
          [-port LinuxGpib:[board_index]]
    	  [-address n]
    	  [-start n] first address to poll, default 0
    	  [-end n] last address to poll, default 30\n";
    exit;
}
