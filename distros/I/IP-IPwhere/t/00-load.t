#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'IP::IPwhere' ) || print "Bail out!\n";
}

diag( "Testing IP::IPwhere $IP::IPwhere::VERSION, Perl $], $^X" );
