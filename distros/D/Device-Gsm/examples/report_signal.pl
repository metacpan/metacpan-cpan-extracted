#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Report signal quality of mobile phone line

use strict;
use Device::Gsm;

print "\nthis is report_signal.pl\n";
print "\nGetting signal quality of your mobile phone line...\n\n";

my $port = $ENV{DEV_GSM_PORT} || ($^O =~ /Win/ ? 'COM2' : '/dev/ttyS1');
my $myport;

print "Select your serial port [$port] : ";
chomp( $myport = <STDIN> );
$myport ||= $port;

my $gsm = new Device::Gsm( port => $myport, log => 'file,signal.log' );

die "cannot create Device::Gsm object!" unless $gsm;

$gsm->connect( baudrate => ($ENV{DEV_GSM_BAUD} || 19200) ) or die "cannot connect to GSM device on [$myport]\n";

print "\nok! connected to gsm phone.\n";

my $dBm = $gsm->signal_quality();

if( $dBm ) {

	print "Signal quality reading: $dBm dBm\n";

} else { 

	print "Could not read signal quality!\n";

}



