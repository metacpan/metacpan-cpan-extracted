#!/usr/bin/perl -T
use strict;
BEGIN {
    chdir 't' if -d 't';
}

use lib '../blib/lib', '../blib/arch';
use Test::More;
note "Testing Perl POD documentation";
eval "use Test::Pod::Coverage 1.08";
plan skip_all => "Test::Pod::Coverage 1.08 required for testing POD coverage" if $@;

# Don't know how to get this from perlcdio ignored.
pod_coverage_ok(
    'perlcdio', 
    { also_private => [ qr/^.*$/ ], },
    "Everything in perlcdio is private as it is auto-generated"
    );
done_testing();
