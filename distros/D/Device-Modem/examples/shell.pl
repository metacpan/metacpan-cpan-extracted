#!/usr/bin/perl
#
# Simple test program that executes a modem `shell'
# to monitor AT command results.
#
# ******************************************
# If it does not work, try with baud = 9600
#
# $Id: shell.pl,v 1.6 2005-04-30 21:45:47 cosimo Exp $

use strict;
use Device::Modem;

if( $> && $< ) {
	print "\n*** REMEMBER to run this program as root if you cannot connect on serial port!\n";
	sleep 3;
}

print "Your serial port? [/dev/ttyS0]\n";
my $port = <STDIN>;
chomp $port;

$port ||= '/dev/ttyS0';

print "Your baud rate? [19200]\n";
my $baud = <STDIN>;
chomp $baud;

$baud ||= 19200;

my $modem = new Device::Modem ( port => $port );
my $stop;

die "Could not connect to $port!\n" unless $modem->connect( baudrate => $baud );


print "Connected to $port.\n\n";

while( not $stop ) {

	print "insert AT command (`stop' to quit)\n";
	print "> ";

	my $AT = <STDIN>;
	chomp $AT;

	if( $AT eq 'stop' ) {
		$stop = 1;
	} else {
		$modem->atsend( $AT . "\r\n" );
		print $modem->answer(), "\n";

	}

}

print "Done.\n";

