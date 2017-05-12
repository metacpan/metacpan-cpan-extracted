#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Hypothesis::API' ) || print "Bail out!\n";
}

diag( "Testing Hypothesis::API $Hypothesis::API::VERSION, Perl $], $^X" );
