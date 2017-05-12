#!/usr/bin/env perl

use strict;

use Test::More tests => 5;
use HTTP::Response;

use_ok('HTTP::DAV');

my $server_msg = q{Method not allowed};
my $fake_405_response = HTTP::Response->new(405, $server_msg);

my $dav = HTTP::DAV->new();

my $result = $dav->what_happened(
    'https://fake.url.for.testing',     # url
    undef,                              # resource
    $fake_405_response,                 # http::response
);

ok(ref $result eq 'HASH', 'A hashref is expected');

is(
    $result->{success} => 0,
    'Requests ending in 405s should be considered failed'
);

is(
    $result->{error_type} => 'ERR_405',
    'RT#38677: 405s are detected as such'
);

like(
    $result->{error_msg} => qr{$server_msg},
    'Server message should be reported as error message'
);

