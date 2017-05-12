#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Email::Assets' ) || print "Bail out!\n";
}

diag( "Testing Email::Assets $Email::Assets::VERSION, Perl $], $^X" );
