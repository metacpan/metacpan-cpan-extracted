#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'List::Unique::DeterministicOrder' ) || print "Bail out!\n";
}

diag( "Testing List::Unique::DeterministicOrder $List::Unique::DeterministicOrder::VERSION, Perl $], $^X" );
