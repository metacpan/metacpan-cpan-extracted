#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Geo::Parse::OSM' ) || print "Bail out!
";
}

diag( "Testing Geo::Parse::OSM $Geo::Parse::OSM::VERSION, Perl $], $^X" );
