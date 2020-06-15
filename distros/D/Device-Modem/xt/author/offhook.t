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

plan tests => 4;

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
	skip "Not connected.", 1 unless $connected;
	diag('testing offhook function...');
	$modem->attention();

	ok($modem->offhook(), 'offhook: properly set');
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
