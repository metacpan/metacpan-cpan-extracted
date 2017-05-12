#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Detergent' ) || print "Bail out!\n";
}

diag( "Testing HTML::Detergent $HTML::Detergent::VERSION, Perl $], $^X" );
