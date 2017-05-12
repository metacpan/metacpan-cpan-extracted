#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Encode::Bootstring' );
}

diag( "Testing Encode::Bootstring $Encode::Bootstring::VERSION, Perl $], $^X" );
