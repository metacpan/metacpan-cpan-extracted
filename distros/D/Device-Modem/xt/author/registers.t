# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib '..';
use Device::Modem;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

$|++;

my $port = $ENV{'DEV_MODEM_PORT'};
my $baud = $ENV{'DEV_MODEM_BAUD'};

unless( $port && $baud ) {
	print "skip 1\nskip 2\nskip 3\n";
	exit;
}

my $modem = Device::Modem->new( port => $port );

if( $modem->connect( baudrate => $baud ) ) {
	print "ok 2\n";
} else {
	print "not ok 2\n";
	die "cannot connect to $port serial port!: $!";
}

print 'testing S-registers functions...', "\n";

my $v1 = $modem->S_register(1);
my $v2 = $modem->S_register(1, 72);
my $v3 = $modem->S_register(1);
my $v4 = $modem->S_register(1, $v1);
my $v5 = $modem->S_register(1);

if( $v1 eq $v5 && $v1 == $v5 &&
	$v2 == 72  && $v3 == 72  &&
	$v4 eq $v1 && $v4 == $v1 ) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}
