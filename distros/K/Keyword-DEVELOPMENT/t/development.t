#!/usr/bin/env perl

BEGIN {
    # just in case someone turned this one
    $ENV{PERL_KEYWORD_DEVELOPMENT} = 1;
}
use lib 'lib';
use Test::More tests => 2;
use Keyword::DEVELOPMENT;

my $value = 0;
DEVELOPMENT {
    $value = 1;
    ok 1, 'This code should be called';
}

is $value, 1, 'Our DEVELOPMENT function should be called';
