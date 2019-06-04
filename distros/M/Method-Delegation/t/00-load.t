#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Method::Delegation' ) || print "Bail out!\n";
}

diag( "Testing Method::Delegation $Method::Delegation::VERSION, Perl $], $^X" );
