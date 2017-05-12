#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'I22r::Translate' ) || print "Bail out!\n";
}

diag( "Testing I22r::Translate $I22r::Translate::VERSION, Perl $], $^X" );
