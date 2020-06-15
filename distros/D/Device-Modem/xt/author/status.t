#!perl

use strict;
use warnings;
use Device::Modem;
use Test::More;

my $port = $ENV{'DEV_MODEM_PORT'} || '';
my $baud = $ENV{'DEV_MODEM_BAUD'} || '';

unless( $port && $baud ) {
	plan skip_all => 'Environment variables: DEV_MODEM_PORT and DEV_MODEM_BAUD are necessary';
	exit;
}
plan tests => 4;

my $modem = Device::Modem->new( port => $port );
isa_ok($modem, 'Device::Modem', 'new: new object instance');

my $res;
my $error = do {
	local $@;
	eval { $res = $modem->connect( baudrate => $baud ) if $modem; };
	$@;
};
is($error, undef, 'connect: no errors');
ok($res, 'connect: successfully connected');

SKIP: {
	skip "Couldn't connect for some reason", 1 unless $res;
	my %status = $modem->status();
	ok(keys %status, 'Status: returned keys');
	for my $key (keys %status) {
		my $stat = $status{$key} ? 'on' : 'off';
		diag("$key signal is $stat\n");
	}
}
