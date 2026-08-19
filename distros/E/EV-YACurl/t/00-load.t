use strict;
use warnings;
use Test::More tests => 6;

use_ok('EV::YACurl');

ok(defined $EV::YACurl::VERSION, "VERSION is set ($EV::YACurl::VERSION)");

EV::YACurl->import(':constants');

can_ok('EV::YACurl', qw(new request priority default_priority));
can_ok('EV::YACurl::Response', qw(getinfo));

ok(defined &CURLOPT_URL, 'CURLOPT_* constants are exported');
cmp_ok(CURLOPT_URL(), '>', 0, 'CURLOPT_URL has a sane value');

diag "libcurl: " . `curl-config --version 2>/dev/null` if $ENV{TEST_VERBOSE};
