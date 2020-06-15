#!perl
use strict;
use Device::Modem;
use Test::More;

my $port = $ENV{'DEV_MODEM_PORT'};
my $baud = $ENV{'DEV_MODEM_BAUD'};

unless( $port && $baud ) {
	plan skip_all => 'Environment variables: DEV_MODEM_PORT and DEV_MODEM_BAUD are necessary';
	exit;
}
plan tests => 5;

my $modem = Device::Modem->new( port => $port );
isa_ok($modem, 'Device::Modem', 'new: new object instance');

my $connected;
my $error = do {
	local $@;
	eval { $connected = $modem->connect( baudrate => $baud ) if $modem; };
	$@;
};
is($error, undef, 'connect: no errors');
ok($connected, 'connect: successfully connected');

SKIP: {
	skip "Couldn't connect for some reason", 2 unless $connected;

	ok($modem->store_number(0, '10880432090000'), 'store_number: Number stored');
	ok($modem->store_number(1, '0432,649062'), 'store_number: Number stored');
}
