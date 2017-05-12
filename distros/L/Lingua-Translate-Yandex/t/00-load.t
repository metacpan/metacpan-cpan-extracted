#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::Translate::Yandex' ) || print "Bail out!\n";
}

diag( "Testing Lingua::Translate::Yandex $Lingua::Translate::Yandex::VERSION, Perl $], $^X" );
