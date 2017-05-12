#!perl -T
use 5.008003;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Brent' ) || print "Bail out!\n";
}

diag( "Testing Math::Brent $Math::Brent::VERSION, Perl $], $^X" );
