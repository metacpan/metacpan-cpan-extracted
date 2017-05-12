#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ham::WSJTX::Logparse' ) || print "Bail out!\n";
}

diag( "Testing Ham::WSJTX::Logparse $Ham::WSJTX::Logparse::VERSION, Perl $], $^X" );
