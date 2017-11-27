#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Martian' ) || print "Bail out!\n";
}

diag( "Testing Martian $Martian::VERSION, Perl $], $^X" );
