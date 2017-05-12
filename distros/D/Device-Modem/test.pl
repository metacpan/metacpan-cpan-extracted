# $Id: test.pl,v 1.18 2005-04-30 21:45:47 cosimo Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use lib '.';
use lib './blib';
use Device::Modem;

$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


# Load Makefile settings
#require '.config.pm';

# If non-win platforms and user is not root, skip tests
# because they access serial port (only accessible under root user)

my $is_windoze = index($^O, 'Win') >= 0;

#if( ! $is_windoze && ( $< || $> ) ) {
#	print "\n\n*** SKIPPING tests. You need root privileges to test modems on serial ports. Sorry\n";
#	print "skip $_\n" for (1..6);
#	exit(0);
#}

unless( $is_windoze || ($< + $> == 0) ) {
	print "\n\n*** REMEMBER to run these tests as `root' where required!\n\n";
	sleep 1;
}

$Device::Modem::port     = $ENV{'DEV_MODEM_PORT'};
$Device::Modem::baudrate = $ENV{'DEV_MODEM_BAUD'} || 19200;

if( $Device::Modem::port eq 'NONE' || $Device::Modem::port eq '' ) {

	print <<NOTICE;

    No serial port set up, so *NO* tests will be executed...
    To enable full testing, you can set these environment vars:

        DEV_MODEM_PORT=[your serial port]    (Ex.: 'COM1', '/dev/ttyS1', ...)
        DEV_MODEM_BAUD=[serial link speed]   (default is 19200)

    On most unix environments, this can be done running:

        DEV_MODEM_PORT=/dev/modem DEV_MODEM_BAUD=19200 make test

    On Win32 systems, you can do:

        set DEV_MODEM_PORT=COM1
        set DEV_MODEM_BAUD=19200
        nmake test (or make test)

NOTICE

	print "skip $_\n" for (2..15);

	exit;

} else {

	print "Your serial port is `$Device::Modem::port' (environment configured)\n";
	print "Link baud rate   is `$Device::Modem::baudrate' (environment configured)\n";

}

# -----------------------------------------------------
# BEGIN OF TESTS
# -----------------------------------------------------

# If tests that increment this counter all *fail*,
# then almost certainly you don't have a gsm device
# connected to your serial port or maybe it's the wrong
# serial port
my $not_connected_guess;

# test text file logging
my $port = $Device::Modem::port;
my $baud = $Device::Modem::baudrate;

my $modem = new Device::Modem( port => $port, log => 'file,test.log', loglevel => 'info' );

if( $modem->connect(baudrate => $baud) ) {
	print "ok 2\n";
} else {
	print "not ok 2\n";
	die "cannot connect to $port serial port!: $!";
}


# Try with AT escape code
my $ans = $modem->attention();
print 'sending attention, modem says `', $ans, "'\n";

if( $ans eq '' ) {
	print "ok 3\n";
} else {
	print "not ok 3\n";
}

# Send empty AT command
$modem->atsend('AT'.Device::Modem::CR);
$ans = $modem->answer();
print 'sending AT, modem says `', $ans, "'\n";

if( $ans =~ /OK/ ) {
	print "ok 4\n";
} else {
	print "not ok 4\n";
	$not_connected_guess++;
}


# This must generate an error!
$modem->atsend('AT@x@@!$#'.Device::Modem::CR);
$ans = $modem->answer();
print 'sending erroneous AT command, modem says `', $ans, "'\n";

if( $ans =~ /ERROR/ ) {
	print "ok 5\n";
} else {
	print "not ok 5\n";
	$not_connected_guess++;
}

$modem->atsend('AT'.Device::Modem::CR);
$modem->answer();

$modem->atsend('ATZ'.Device::Modem::CR);
$ans = $modem->answer();
print 'sending ATZ reset command, modem says `', $ans, "'\n";

if( $ans =~ /OK/ ) {
	print "ok 6\n";
} else {
	print "not ok 6\n";
	$not_connected_guess++;
}



print 'testing echo enable/disable...', "\n";
if( $modem->echo(1) && $modem->echo(0) ) {
	print "ok 7\n";

} else {
	print "not ok 7\n";
	$not_connected_guess++;
}

print 'testing offhook function...', "\n";
if( $modem->offhook() ) {
	print "ok 8\n";
} else {
	print "not ok 8\n";
}

sleep(1);

# 9
print 'hanging up...', "\n";
if( $modem->hangup() =~ /OK/ ) {
	print "ok 9\n";
} else {
	print "not ok 9\n";
	$not_connected_guess++;
}


# --- 10 ---
print 'testing is_active() function...', "\n";
if( $modem->is_active() ) {
	print "ok 10\n";
} else {
	print "not ok 10\n";
	$not_connected_guess += 10;
}


# --- 11 ---
print 'testing S registers read/write...', "\n";

my $reg = 1;
my $v1 = $modem->S_register($reg);
my $v2 = $modem->S_register($reg, 72);
my $v3 = $modem->S_register($reg);
my $v4 = $modem->S_register($reg, $v1);
my $v5 = $modem->S_register($reg);

if( $v1 eq $v5 && $v1 == $v5 &&
    $v2 == 72  && $v3 == 72  &&
    $v4 eq $v1 && $v4 == $v1 ) {
	print "ok 11\n";
} else {
	$not_connected_guess++;
	print "not ok 11\n";
}

# --- 12 ---
print 'test reading several lines of data (maybe this test fails, it is badly written) ...', "\n";

$modem->atsend('ATI4'.Device::Modem::CR);
$ans = $modem->answer();
# Probably here ans is ERROR, or something else that depends on modem model
if( length($ans) < 5 || length($ans) > 300 ) {
	print "ok 12\n";
} else {
	print "nok 12\n";
}

# --- 13 ---

print 'testing status of modem signals...', "\n";

my $signals_on = 0;
my %status = $modem->status();
foreach( keys %status ) {
	print "$_ signal is ", $status{$_} ? 'on' : 'off', "\n";
	$signals_on++ if $status{$_};
}

if( $signals_on > 1 ) {
	print "ok 13\n";
} else {
	print "not ok 13\n";
	$not_connected_guess++;
}


if( $not_connected_guess >= 4 ) {


	print <<EOT;

--------------------------------------------------------
Results of your test procedure indicate almost
certainly that you *DON'T HAVE* a modem device connected
to your *serial port* or maybe it's the wrong port.
--------------------------------------------------------

EOT

	sleep 2;

}

