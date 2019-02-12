#!perl -T
use 5.010001;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Logic::TruthTable' ) || print "Bail out!\n";
}

diag( "Testing Logic::TruthTable $Logic::TruthTable::VERSION, Perl $], $^X" );
