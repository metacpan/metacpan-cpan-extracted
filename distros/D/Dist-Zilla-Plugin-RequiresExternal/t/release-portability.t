#!/usr/bin/env perl

BEGIN {
    unless ( $ENV{RELEASE_TESTING} ) {
        print qq{1..0 # SKIP these tests are for release candidate testing\n};
        exit;
    }
}

BEGIN {
    if ( not $ENV{RELEASE_TESTING} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'these tests are for release candidate testing' );
    }
}

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)
use Test::More;

eval 'use Test::Portability::Files';
plan skip_all => 'Test::Portability::Files required for testing portability'
    if $@;

options( test_one_dot => 0 );
run_tests();
