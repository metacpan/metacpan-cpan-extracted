#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'HTTP::PublicKeyPins' ) || print "Bail out!\n";
}

diag( "Testing HTTP::PublicKeyPins $HTTP::PublicKeyPins::VERSION, Perl $], $^X" );
