#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lingua::Translate::Bing' ) || print "Bail out!\n";
}

diag( "Testing Lingua::Translate::Bing $Lingua::Translate::Bing::VERSION, Perl $], $^X" );
