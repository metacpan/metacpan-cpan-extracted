#!/usr/bin/env perl

use strict;
use Test::More tests => 7;

use_ok('HTTP::DAV');
use_ok('HTTP::DAV::Comms');

$HTTP::DAV::DEBUG =
$HTTP::DAV::DEBUG = 3;

my $netloc = 'mylocation';
my $realm = 'myrealm';
my $user = 'randomuser';
my $pass = '12345';

my $ua = HTTP::DAV::UserAgent->new();
my $existing_credentials = $ua->credentials($netloc, $realm);

is ($existing_credentials, undef, 'No credentials defined at start');
$ua->credentials($netloc, $realm, $user, $pass);

$existing_credentials = $ua->credentials($netloc, $realm);
is ($existing_credentials, "$user:$pass", 'credentials() called in scalar context');

my @cred = $ua->credentials($netloc, $realm);

is(scalar @cred, 2, 'credentials() called in list context');
is($cred[0], $user, 'credentials() called in list context');
is($cred[1], $pass, 'credentials() called in list context');

