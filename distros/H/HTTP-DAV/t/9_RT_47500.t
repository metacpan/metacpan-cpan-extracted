#!/usr/bin/env perl

use strict;
use Test::More tests => 7;

use_ok('HTTP::DAV');
use_ok('HTTP::DAV::Comms');

#$HTTP::DAV::DEBUG =
#$HTTP::DAV::DEBUG = 0;

# Normalize netloc with port (:80)
# or we might miss the hash key
my $netloc = 'mylocation:80';
my $realm = 'myrealm';
my $user = 'randomuser';
my $pass = '12345';

my $ua = HTTP::DAV::UserAgent->new();
my $existing_credentials = $ua->credentials($netloc, $realm);

ok (
	! exists $ua->{basic_authentication}->{$netloc}->{$realm},
	"Shouldn't autovivify the $netloc/$realm hash key when accessing it"
);

$ua->credentials($netloc, $realm, $user, $pass);

is_deeply (
	$ua->{basic_authentication}->{$netloc}->{$realm},
	[ $user, $pass ],
	'Credentials are correctly set',
);

my @cred = $ua->credentials($netloc, $realm);

is(scalar @cred, 2, 'credentials() has 2 elements');
is($cred[0], $user, 'credentials() stored correctly');
is($cred[1], $pass, 'credentials() stored correctly');

