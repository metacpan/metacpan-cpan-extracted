#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Medical::DukePTP' );
}

diag( "Testing Medical::DukePTP $Medical::DukePTP::VERSION, Perl $], $^X" );
