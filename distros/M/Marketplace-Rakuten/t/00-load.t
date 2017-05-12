#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Marketplace::Rakuten' ) || print "Bail out!\n";
}

diag( "Testing Marketplace::Rakuten $Marketplace::Rakuten::VERSION, Perl $], $^X" );
