#!/usr/bin/perl
#
# Get GSM network name 

use strict;
use Device::Gsm;

my $port = $ENV{DEV_GSM_PORT} or die "Set DEV_GSM_PORT environment variable!";
my $gsm = new Device::Gsm( port => $port, log => 'file,network.log', loglevel => 'info' );

die "cannot create Device::Gsm object!" unless $gsm;

$gsm->connect( baudrate => ($ENV{DEV_GSM_BAUD} || 19200) )
    or die "cannot connect to GSM device on [$port]\n";

$gsm->register() or die "Can't register to network";

my($network, $code) = $gsm->network();

if($network || $code) {
	print "Network name the gsm software returns is [$network]\n";
    print "Its gsm code is [$code]\n";
} else { 
	print "No network name...\n";
}



