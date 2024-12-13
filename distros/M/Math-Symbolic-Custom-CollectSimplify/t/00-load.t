#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Symbolic::Custom::CollectSimplify' ) || print "Bail out!\n";
}

diag( "Testing Math::Symbolic::Custom::CollectSimplify $Math::Symbolic::Custom::CollectSimplify::VERSION, Perl $], $^X" );
