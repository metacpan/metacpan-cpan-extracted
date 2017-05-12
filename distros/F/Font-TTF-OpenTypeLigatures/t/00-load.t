#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Font::TTF::OpenTypeLigatures' );
}

diag( "Testing Font::TTF::OpenTypeLigatures $Font::TTF::OpenTypeLigatures::VERSION, Perl $], $^X" );
