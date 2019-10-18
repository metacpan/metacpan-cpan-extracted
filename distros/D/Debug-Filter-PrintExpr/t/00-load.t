#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Debug::Filter::PrintExpr' ) || print "Bail out!\n";
}

diag( "Testing Debug::Filter::PrintExpr $Debug::Filter::PrintExpr::VERSION, Perl $], $^X" );
