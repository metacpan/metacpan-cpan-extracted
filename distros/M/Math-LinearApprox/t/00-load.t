#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::LinearApprox' ) || print "Bail out!\n";
}

diag( "Testing Math::LinearApprox $Math::LinearApprox::VERSION, Perl $], $^X" );
