#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Journal::ImpactFactor' ) || print "Bail out!\n";
}

diag( "Testing Journal::ImpactFactor $Journal::ImpactFactor::VERSION, Perl $], $^X" );
