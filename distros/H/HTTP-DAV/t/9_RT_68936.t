#!/usr/bin/env perl
#
# RT #68936, errors() throws an undefined reference exception
#

use strict;
use warnings;
use Test::More tests => 2;

use HTTP::DAV;

my $dav = HTTP::DAV->new();
ok($dav);

my @errors;

eval {
    @errors = $dav->errors();
    ok(@errors == 0, "No errors to be returned");
} or do {
    ok(0, "errors() method failed miserably: $@");
};

