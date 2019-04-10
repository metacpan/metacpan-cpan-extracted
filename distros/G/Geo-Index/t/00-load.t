#!perl
# was: #!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Geo::Index' ) || print "Bail out!
";
}

diag( "Testing Geo::Index $Geo::Index::VERSION, Perl $], $^X" );
