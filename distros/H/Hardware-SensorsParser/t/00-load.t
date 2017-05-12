#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Hardware::SensorsParser' ) || print "Bail out!\n";
}

diag( "Testing Hardware::SensorsParser $Hardware::SensorsParser::VERSION, Perl $], $^X" );
