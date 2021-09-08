#!/usr/bin/env perl

BEGIN {
    # just in case someone turned this one
    $ENV{PERL_KEYWORD_DEVELOPMENT} = 0;
}
use lib 'lib';
use Test::More;
use Keyword::DEVELOPMENT '-production';

my $value = 0;
DEVELOPMENT {
    $value = 1;
    fail "DEVELOPMENT should be off, so we shouldn't get to here";
}
is $value, 0, 'Our DEVELOPMENT function should not be called';

$value = 0;
PRODUCTION {
    $value = 1;
    pass "DEVELOPMENT should be off, so PRODUCTION blocks should fire";
}
ok $value, '... and be able to alter variables in its scope.';

done_testing;

