#!/usr/bin/perl
#
# Short example of use for Device::Gsm class

use strict;
use Device::Gsm;

print "\nthis is send_sms.pl\n";
print "I hope I can send an SMS on your GSM phone attached to...\n";

my $port = $^O =~ /Win/ ? 'COM2' : '/dev/ttyS1';
my $myport;

my $pin  = '0000';
my $mypin;

print "Select your serial port [$port] : ";
chomp( $myport = <STDIN> );
$myport ||= $port;

print "Insert your PIN number if you need to register to GSM network [$pin] : ";
chomp( $mypin = <STDIN> );
$mypin ||= $pin;
$mypin =~ s/\D//g;
$mypin = substr( $mypin, 0, 4 );

my $gsm = new Device::Gsm( port => $myport, pin => $mypin, log => 'file,send.log' );

die "cannot create Device::Gsm object!" unless $gsm;

#
# If you have problems with bad characters being trasmitted across serial link,
# try different baud rates, as below...
#
# .---------------------------------.
# | Model (phone/modem) |  Baudrate |
# |---------------------+-----------|
# | Falcom Swing (A2D)  |      9600 |
# | Siemens C35/C45     |     19200 |
# | Digicom             |      9600 |
# | Nokia Communicator  |      9600 |
# `---------------------------------'
#

$gsm->connect( baudrate => 9600 ) or die "cannot connect to GSM device on [$myport]\n";
$gsm->register() or die "cannot register on GSM network: check pin and/or network signal!"; 

print "\nok! connected and registered to network.\n";

my $number;
do { 
	print "\nRecipient number (ex.: +490320201020 or 0320201020): ";
	chomp( $number = <STDIN> );
} until $number;

my $content;
do { 
	print "\nSMS Text (max 160 chars):\n";
	chomp( $content = <STDIN> );
} until $content;

$content = substr( $content, 0, 160 );

my $lOk = $gsm->send_sms(
	content => $content,
	recipient => $number,
	class     => 'normal'     # try `flash'
);

if( $lOk ) {

	print "SMS sent!\n" ;

} else { 

	print "Error in sending!\n";

}



