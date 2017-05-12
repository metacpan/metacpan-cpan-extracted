#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'LucyX::Suggester' );
}

diag( "Testing LucyX::Suggester $LucyX::Suggester::VERSION, Perl $], $^X" );
