#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Debug::Comments' ) || print "Bail out!\n";
}

diag( "Testing Debug::Comments $Debug::Comments::VERSION, Perl $], $^X" );
