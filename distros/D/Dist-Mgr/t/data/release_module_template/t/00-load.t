#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Acme::STEVEB' ) || print "Bail out!\n";
}

diag( "Testing Acme::STEVEB $Acme::STEVEB::VERSION, Perl $], $^X" );
