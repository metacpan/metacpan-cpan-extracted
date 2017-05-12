#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Math::Geometry::Multidimensional' ) || print "Bail out!\n";
}

diag( "Testing Math::Geometry::Multidimensional $Math::Geometry::Multidimensional::VERSION, Perl $], $^X" );
