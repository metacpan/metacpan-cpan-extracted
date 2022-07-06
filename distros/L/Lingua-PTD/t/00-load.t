#!perl
use v5.14;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lingua::PTD' ) || print "Bail out!\n";
}

diag( "Testing Lingua::PTD $Lingua::PTD::VERSION, Perl $], $^X" );
