#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Marathon' ) || print "Bail out!\n";
}

diag( "Testing Marathon $Marathon::VERSION, Perl $], $^X" );
