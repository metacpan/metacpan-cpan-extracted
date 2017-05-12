#!/usr/bin/env perl

use Test::More;

BEGIN {
    plan tests => 2;
    use_ok( 'Google::Cloud::Speech' ) || print "Bail out!\n";
    use_ok( 'Google::Cloud::Speech::Auth' ) || print "Bail out!\n";
}
