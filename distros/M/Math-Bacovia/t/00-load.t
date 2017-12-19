#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Bacovia' ) || print "Bail out!\n";
}

diag( "Testing Math::Bacovia $Math::Bacovia::VERSION, Perl $], $^X" );
