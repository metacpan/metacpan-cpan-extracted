#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'HTML::Barcode::Code93' ) || print "Bail out!\n";
}

diag( "Testing HTML::Barcode::Code93 $HTML::Barcode::Code93::VERSION, Perl $], $^X" );
