#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'MD5Check' ) || print "Bail out!\n";
}

diag( "Testing MD5Check $MD5Check::VERSION, Perl $], $^X" );
