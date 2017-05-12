#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'I22r::Translate::Microsoft' ) || print "Bail out!\n";
}

diag( "Testing I22r::Translate::Microsoft $I22r::Translate::Microsoft::VERSION, Perl $], $^X" );
