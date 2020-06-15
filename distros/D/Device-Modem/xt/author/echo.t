#!perl

use strict;
use Device::Modem;
use Test::More;

my %config;
parse_config();

my $port = $config{tty} || $ENV{DEV_MODEM_PORT} || $Device::Modem::DEFAULT_PORT;

unless( $port ) {
	plan skip_all => 'Environment variables: DEV_MODEM_PORT and DEV_MODEM_BAUD are necessary';
	exit;
}
diag("Testing against port $port.  Set env DEV_MODEM_PORT to change");

plan tests => 10;

my $modem = Device::Modem->new( port => $port );
isa_ok($modem, 'Device::Modem', 'new: new object instance');

my $connected;
my $error = do {
	local $@;
	eval { $connected = $modem->connect() if $modem; };
	$@;
};
is($error, undef, 'connect: no errors');
ok($connected, 'connect: successfully connected');

SKIP: {
	skip "Not connected.", 7 unless $connected;

	my $echo = $modem->echo(1);
	ok($echo, "echo: echo turned on");
	ECHO: {
		skip "No Echo", 3 unless $echo;
		diag("Sending AT@@@ string...");
		ok($modem->atsend('AT@@@'.Device::Modem::CR), 'atsend: AT@@@ sent');
		my $ans = $modem->answer();
		like($ans, qr/AT@@@/, 'answer: contains AT@@@');
		like($ans, qr/ERROR/, 'answer: contains ERROR');
	}

	$echo = $modem->echo(0);
	ok($echo, "echo: echo turned off");
	ECHO: {
		skip "Couldn't turn off echo", 2 unless $echo;
		diag("Sending AT@@@ string");
		ok($modem->atsend('AT@@@'.Device::Modem::CR), 'atsend: AT@@@ sent');
		my $ans = $modem->answer();
		like($ans, qr/ERROR/, 'answer: contains ERROR');
	}
}

sub parse_config {
	open my $fh, '<', '../.config' or return undef;
	while (my $line = <$fh>) {
		chomp $line;
		my @t = split ' ', $line, 2;
		$config{ $t[0] } = $t[1];
	}
	return undef;
}
