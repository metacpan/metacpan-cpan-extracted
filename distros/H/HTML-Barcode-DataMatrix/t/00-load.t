#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Barcode::DataMatrix' ) || print "Bail out!\n";
}

diag( "Testing HTML::Barcode::DataMatrix $HTML::Barcode::DataMatrix::VERSION, Perl $], $^X" );
