#!perl -T
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Karel' ) || print "Bail out!\n";
}

diag( "Testing Karel $Karel::VERSION, Perl $], $^X" );
