#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Lingua::StarDict::Writer' ) || print "Bail out!\n";
}

diag( "Testing Lingua::StarDict::Writer $Lingua::StarDict::Writer::VERSION, Perl $], $^X" );
