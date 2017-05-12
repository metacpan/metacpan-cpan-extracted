#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::EntityReference' ) || print "Bail out!\n";
}

diag( "Testing HTML::EntityReference $HTML::EntityReference::VERSION, Perl $], $^X" );
