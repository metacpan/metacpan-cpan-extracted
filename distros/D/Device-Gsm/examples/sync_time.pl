#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Get date and time from phone 

use strict;
use lib 'blib/arch';
use lib 'blib';
use Device::Gsm;

print "\nthis is sync_time.pl\n";
print "This script tries to set phone date/time to that of your PC clock\n";

my $gsm = conn();

print "\nok! connected to gsm phone.\n";
print "Setting phone date/time to [".localtime()."]...\n";

if( my $time = $gsm->datetime(localtime) ) {
	print "Time of phone set correctly to $time!\n";
} else {
	print "Failed to set time!\n";
}

# End






sub conn {
	my $port = $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1';
	my $myport;
	print "Select your serial port [$port] : ";
	chomp( $myport = <STDIN> );
	$myport ||= $port;
	my $gsm = new Device::Gsm( port => $myport, log => 'file,sync_time.log', loglevel=>'info' );
	die "cannot create Device::Gsm object!" unless $gsm;
	$gsm->connect( baudrate => 19200 ) or die "cannot connect to GSM device on [$myport]\n";
	return $gsm;
}

