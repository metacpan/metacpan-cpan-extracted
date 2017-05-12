#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'FSpot::DbTool' ) || print "Bail out!
";
}

diag( "Testing FSpot::DbTool $FSpot::DbTool::VERSION, Perl $], $^X" );
