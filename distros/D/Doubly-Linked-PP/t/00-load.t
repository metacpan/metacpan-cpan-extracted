#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Doubly::Linked::PP' ) || print "Bail out!\n";
}

diag( "Testing Doubly::Linked::PP $Doubly::Linked::PP::VERSION, Perl $], $^X" );
