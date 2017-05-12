#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::Dir::Map' ) || print "Bail out!
";
}

diag( "Testing File::Dir::Map $File::Dir::Map::VERSION, Perl $], $^X" );
