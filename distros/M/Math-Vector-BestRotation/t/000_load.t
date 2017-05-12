#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Math::Vector::BestRotation' ) || print "Bail out!
";
}

diag( "Testing Math::Vector::BestRotation $Math::Vector::BestRotation::VERSION, Perl $], $^X" );
