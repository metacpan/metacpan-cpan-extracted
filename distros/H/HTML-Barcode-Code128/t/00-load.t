#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Barcode::Code128' ) || print "Bail out!\n";
}

diag( "Testing HTML::Barcode::Code128 $HTML::Barcode::Code128::VERSION, Perl $], $^X" );
