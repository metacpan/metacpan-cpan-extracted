#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Revhash' ) || print "Bail out!\n";
}

diag( "Testing Math::Revhash $Math::Revhash::VERSION, Perl $], $^X" );
