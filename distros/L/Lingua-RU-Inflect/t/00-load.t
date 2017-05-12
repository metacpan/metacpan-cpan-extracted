#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::RU::Inflect' );
}

diag( "Testing Lingua::RU::Inflect $Lingua::RU::Inflect::VERSION, Perl $], $^X" );
