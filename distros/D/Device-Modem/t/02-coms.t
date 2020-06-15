#!perl

use strict;
use warnings;
use Device::Modem;

use Test::More;

my $port = $ENV{'DEV_MODEM_PORT'};
my $baud = $ENV{'DEV_MODEM_BAUD'} || 19200;
my $is_windows = ($^O eq 'MSWin32')? 1: 0;
my $is_root = ($< + $> == 0)? 1: 0;

if (!$is_windows && !$is_root) {
	plan skip_all => 'These tests require root access on non-Windows devices';
	exit;
}
unless( $port && $baud ) {
	plan skip_all => 'Environment variables: DEV_MODEM_PORT and DEV_MODEM_BAUD are necessary';
	exit;
}
$Device::Modem::port     = $port;
$Device::Modem::baudrate = $baud;

if ($Device::Modem::port eq 'NONE' || !$Device::Modem::port) {
	diag(<<NOTICE);

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
	plan skip_all => 'No modem found';
	exit();
}
plan tests => 25;
diag "Your serial port is `$Device::Modem::port' (environment configured)";
diag "Link baud rate   is `$Device::Modem::baudrate' (environment configured)";


my $modem = Device::Modem->new(port => $port, log => 'file,test.log', loglevel => 'info');
isa_ok($modem, 'Device::Modem', 'new: new object instance');

my $res;
my $error = do {
	local $@;
	eval { $res = $modem->connect( baudrate => $baud ) if $modem; };
	$@;
};
is($error, undef, 'connect: no errors');
ok($res, 'connect: successfully connected to serial port $port');

SKIP: {
	skip "No modem connection", 9 unless $res;
	# Try with AT escape code
	my $ans = $modem->attention();
	is($ans, '', 'attention: correctly got empty response');

	# Send empty AT command
	ok($modem->atsend('AT'.Device::Modem::CR), 'atsend: sent ATdevice');
	$ans = $modem->answer();
	like($ans, qr/OK/, 'answer: contains OK');

	# This must generate an error!
	ok($modem->atsend('AT@x@@!$#'.Device::Modem::CR), 'atsend: invalid ATdevice');
	$ans = $modem->answer();
	like($ans, qr/ERROR/, 'answer: contains proper ERROR response');

	ok($modem->atsend('AT'.Device::Modem::CR), 'atsend: sent ATdevice after error');
	$ans = $modem->answer();
	like($ans, qr/OK/, 'answer: contains OK');

	ok($modem->atsend('ATZ'.Device::Modem::CR), 'atsend: ATZ reset command');
	$ans = $modem->answer();
	like($ans, qr/OK/, 'answer: contains OK');
}

SKIP: {
	skip "No modem connection", 3 unless $res;
	ok($modem->echo(1), 'echo: on');
	ok($modem->echo(0), 'echo: off');

	ok($modem->offhook(), 'offhook: ok');
}

SKIP: {
	skip "No modem connection", 2 unless $res;
	my $res = $modem->hangup();
	like($res, qr/OK/, 'hangup: got OK response');

	ok($modem->is_active(), 'is_active: still OK');
}

SKIP: {
	skip "No modem connection", 5 unless $res;
	my $reg = 1;
	my $v1 = $modem->S_register($reg);
	is(defined($v1), 'S_register: got a value');
	my $v2 = $modem->S_register($reg, 72);
	is($v2, 72, 'S_register: set value to 72');
	my $v3 = $modem->S_register($reg);
	is($v3, 72, 'S_registor: got value 72');
	my $v4 = $modem->S_register($reg, $v1);
	is($v4, $v1, 'S_register: set value to $v1');
	my $v5 = $modem->S_register($reg);
	is($v5, $v1, 'S_register: got value $v1');
}

SKIP: {
	skip "No modem connection", 3 unless $res;
	ok($modem->atsend('ATI4'.Device::Modem::CR), 'atsend: ATI4');
	my $ans = $modem->answer();
	unlike($ans, qr/ERROR/, 'answer: does not contain ERROR');

	my %status = $modem->status();
	ok(keys %status, 'Status: returned keys');
	for my $key (keys %status) {
		my $stat = $status{$key} ? 'on' : 'off';
		diag("$key signal is $stat\n");
	}
}
