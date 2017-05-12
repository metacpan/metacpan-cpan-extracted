#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Games::JackThief' ) || print "Bail out!\n";
}

diag( "Testing Games::JackThief $Games::JackThief::VERSION, Perl $], $^X" );
