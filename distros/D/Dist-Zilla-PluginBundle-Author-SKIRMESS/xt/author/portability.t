#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::Test::XT::Test::Portability::Files 0.004

BEGIN {
    if ( !-f 'MANIFEST' ) {
        print "1..0 # SKIP No MANIFEST file\n";
        exit 0;
    }
}

use Test::Portability::Files;

options( test_one_dot => 0 );
run_tests();
