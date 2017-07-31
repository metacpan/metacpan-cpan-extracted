#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'LinAlg::Vector' ) || print "Bail out!\n";
}

diag( "Testing LinAlg::Vector $LinAlg::Vector::VERSION, Perl $], $^X" );
