#!/usr/bin/env perl
# Test that calling the exported glob() without & or package qualifier
# returns the same results as FastGlob::glob() — no spurious extra values.
# Regression test for https://github.com/atoomic/FastGlob/issues/1

use strict;
use warnings;

use Test::More;
use FastGlob;    # imports glob() into this namespace via @EXPORT

# When FastGlob is loaded and glob() is called via &glob (the imported sub),
# the result must not contain any spurious extra values (e.g. a trailing 0).
# We use &glob() syntax because on older Perls (<=5.16) the parser treats bare
# glob() as the CORE::glob keyword unless a ($) prototype is present.
# The ($) prototype was removed because it triggered CORE::glob's iterator
# semantics, which appended a spurious 0 after the real results.

{
    my @result = &glob(".");
    is( scalar @result, 1,    '&glob(".") returns exactly one result' );
    is( $result[0],     '.',  '&glob(".") returns "."' );
    ok( !grep { !defined $_ || $_ eq '0' || $_ eq '' } @result,
        '&glob(".") contains no spurious false values' );
}

{
    my @result = &glob("..");
    is( scalar @result, 1,    '&glob("..") returns exactly one result' );
    is( $result[0],     '..', '&glob("..") returns ".."' );
}

{
    # Results from exported &glob() must match FastGlob::glob()
    my @via_export   = &glob("*");
    my @via_package  = FastGlob::glob("*");
    is_deeply( [ sort @via_export ], [ sort @via_package ],
        'exported &glob("*") matches FastGlob::glob("*")' );
    ok( !grep { !defined $_ || $_ eq '0' } @via_export,
        'exported &glob("*") contains no spurious 0 values' );
}

done_testing;
