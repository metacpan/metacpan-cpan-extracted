#!/usr/bin/env perl

BEGIN {
    # just in case someone turned this one
    $ENV{PERL_KEYWORD_DEVELOPMENT} = 0;
}
use lib 'lib';
use Test::More tests => 1;
use Keyword::DEVELOPMENT;

my $value = 0;
DEVELOPMENT {
    $value = 1;
    fail "DEVELOPMENT should be off, so we shouldn't get to here";
}

is $value, 0, 'Our DEVELOPMENT function should not be called';
