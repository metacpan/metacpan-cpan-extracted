#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::DWT::UDWT' ) || print "Bail out!\n";
}

diag( "Testing Math::DWT::UDWT $Math::DWT::UDWT::VERSION, Perl $], $^X" );
