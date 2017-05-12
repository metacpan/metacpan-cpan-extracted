#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Message::MongoDB' ) || print "Bail out!\n";
}

diag( "Testing Message::MongoDB $Message::MongoDB::VERSION, Perl $], $^X" );
