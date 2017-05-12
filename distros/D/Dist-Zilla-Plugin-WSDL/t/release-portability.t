#!/usr/bin/env perl -T

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::More;
use Test::Requires;

if ( not $ENV{RELEASE_TESTING} ) {
    plan skip_all => 'these tests are for release candidate testing';
}

test_requires 'Test::Portability::Files';
options( test_one_dot => 0 );
run_tests();
