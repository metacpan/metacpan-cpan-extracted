#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Math::Geometry::Delaunay' ) || print "Bail out!
";
}

diag( "Testing Math::Geometry::Delaunay $Math::Geometry::Delaunay::VERSION, Perl $], $^X" );
