#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Permutation' ) || print "Bail out!\n";
}

diag( "Testing Math::Permutation $Math::Permutation::VERSION, Perl $], $^X" );
