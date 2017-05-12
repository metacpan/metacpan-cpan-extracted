#!/usr/bin/env perl

use strict;
use Test::More tests => 5;
use HTTP::Response;

use_ok('HTTP::DAV');
    
my $server_msg = q{Protocol scheme 'https' is not supported};
my $fake_501_response = HTTP::Response->new(501, $server_msg);

my $dav = HTTP::DAV->new();

my $result = $dav->what_happened(
    'https://fake.url.for.testing',     # url
    undef,                              # resource
    $fake_501_response,                 # http::response
);

ok(ref $result eq 'HASH', 'Has to return a hashref');
is($result->{success} => 0, 'Requests ending in 501s should be considered failed');
is($result->{error_type} => 'ERR_501', '501s are detected as such');
like($result->{error_msg} => qr{$server_msg}, 'Server message should be reported as error message');

