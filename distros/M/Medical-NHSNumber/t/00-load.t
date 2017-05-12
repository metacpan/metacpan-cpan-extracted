#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Medical::NHSNumber' );
}

diag( "Testing Medical::NHSNumber $Medical::NHSNumber::VERSION, Perl $], $^X" );
