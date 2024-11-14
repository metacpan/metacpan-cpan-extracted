#!perl
use 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82;
eval 'use Map::Tube::London';
plan skip_all => 'Map::Tube::London required for this test' if $@;

BEGIN {
    use_ok('Map::Tube::Plugin::FuzzyFind') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Plugin::FuzzyFind $Map::Tube::Plugin::FuzzyFind::VERSION, Perl $], $^X" );

my $tube = new_ok( 'Map::Tube::London' );
can_ok( $tube, 'fuzzy_find' );

plan tests => 3;

