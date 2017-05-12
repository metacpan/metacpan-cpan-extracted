#!/usr/bin/perl
#
# Short example of use for Device::Gsm class
# Script that reads all SMS stored on SIM

use strict;
use lib '../lib';
use lib '../';
use Device::Gsm;

print "\nthis is read_messages.pl\n";
print "\nTrying to read all messages you have on your SIM card...\n";

my $port = $ENV{'DEV_GSM_PORT'} || ( $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1' );
my $myport;

my $pin  = $ENV{'DEV_GSM_PIN'} || '0000';
my $mypin;

unless( $port ) {
	print "Select your serial port [$port] : ";
	chomp( $myport = <STDIN> );
}
$myport ||= $port;

unless( $pin ) {
	print "Insert your PIN number if you need to register to GSM network [$pin] : ";
	chomp( $mypin = <STDIN> );
	$mypin =~ s/\D//g;
	$mypin = substr( $mypin, 0, 4 );
}
$mypin ||= $pin;

my $gsm = new Device::Gsm(
	port => $myport,
	log => 'file,messages.log',
    loglevel => 'debug'
);

die "cannot create Device::Gsm object!" unless $gsm;

my $baud = $ENV{'DEV_GSM_BAUD'} || 9600;

print "Connecting on $myport port at $baud baud ...";

$gsm->connect( baudrate => $baud ) or die "cannot connect to GSM device on [$myport]\n";

print " ok\n";
print "Registering on GSM network...";

$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print " ok\n";

print "Connected and registered to network.\n";

my @msg = $gsm->messages();
my $lOk = scalar @msg;

if( $lOk ) {

	print "You have messages!\n" ;

	my $n = 0;
	foreach( @msg ) {
		my $sms = $_;
		next unless defined $sms;
		print '-' x 60, "\n", "MESSAGE N. $n\n";
		print 'Type   ',($sms->type() eq Device::Gsm::Sms::SMS_SUBMIT ? 'SUBMIT' : 'DELIVER'), "\n";
		print 'Status ', $sms->status(), "\n";
		print 'From   ', $sms->sender(), "\n";
		print 'To     ', $sms->recipient(), "\n";
		print 'Text   [', $sms->text(), "]\n";
		$n++;
		<STDIN>;
	}

} else { 

	print "No message on SIM, or error during read!\n";

}




