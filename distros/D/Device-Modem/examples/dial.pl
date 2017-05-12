# $Id: dial.pl,v 1.3 2005-04-30 21:45:47 cosimo Exp $
#
# This script tries to dial a number taken from STDIN
# or as first argument.
# 
# Example:
#   perl dial.pl 012,3456789
#
# 03/06/2002 Cosimo
#

use Device::Modem;

my %config;
my $port;

if( open CACHED_CONFIG, '< ../.config' ) {
	while( <CACHED_CONFIG> ) {
		my @t = split /[\s\t]+/;
		$config{ $t[0] } = $t[1];
	}
	close CACHED_CONFIG;
}

if( $config{'tty'} ) {

	print "Your serial port is `$config{'tty'}' (cached)\n";
	$port ||= $config{'tty'};

} else {

	$config{'tty'} = $Device::Modem::DEFAULT_PORT; 

	print "What is your serial port? [$config{'tty'}] ";
	chomp( $port = <STDIN> );
	$port ||= $config{'tty'};

	if( open( CONFIG, '>../.config' ) ) {
		print CONFIG "tty\t$port\n";
		close CONFIG;
	}

}

my $modem = new Device::Modem( port => $port );

if( $modem->connect( baudrate => $config{'baud'} || 19200 ) ) {
	print "ok connected.\n";
} else {
	die "cannot connect to $port serial port!: $!";
}

my $number = $ARGV[0];

while( ! $number ) {
	print "\nInsert the number to dial: \n";
	$number = <STDIN>;
	chomp $number;
	$number =~ s/\D//g;
}

print '- trying to dial [', $number, ']', "\n";

if( $lOk = $modem->dial($number,30) ) {

	print "Ok, number dialed\n";

} else {

	print "No luck!\n";

}
