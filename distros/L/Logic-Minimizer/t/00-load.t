#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Logic::Minimizer' ) || print "Bail out!\n";
}

diag( "Testing Logic::Minimizer $Logic::Minimizer::VERSION, Perl $], $^X" );
