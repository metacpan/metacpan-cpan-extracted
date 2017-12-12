#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 2;

BEGIN {
    use_ok( 'Math::VectorXYZ' ) || print "Bail out!\n";
    use_ok( 'Math::VectorXYZ::2D' ) || print "Bail out!\n";
}

diag( "Testing Math::VectorXYZ $Math::VectorXYZ::VERSION, Perl $], $^X" );
