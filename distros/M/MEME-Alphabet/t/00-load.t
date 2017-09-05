#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MEME::Alphabet' ) || print "Bail out!\n";
}

diag( "Testing MEME::Alphabet $MEME::Alphabet::VERSION, Perl $], $^X" );
