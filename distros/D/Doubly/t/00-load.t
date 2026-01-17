#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Doubly' ) || print "Bail out!\n";
    use_ok( 'Doubly::Pointer' ) || print "Bail out!\n";
}

diag( "Testing Doubly $Doubly::VERSION, Doubly::Pointer $Doubly::Pointer::VERSION, Perl $], $^X" );
