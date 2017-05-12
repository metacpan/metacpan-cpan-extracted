#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::JQuery' ) || print "Bail out!\n";
}

diag( "Testing HTML::JQuery $HTML::JQuery::VERSION, Perl $], $^X" );
