#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'JQuery::Mobile' ) || print "Bail out!\n";
}

diag( "Testing JQuery::Mobile $JQuery::Mobile::VERSION, Perl $], $^X" );
