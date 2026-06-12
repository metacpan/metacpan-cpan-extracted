#!perl
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::More 0.82 tests => 3;
use lib 't/';
use Sample;

BEGIN {
    use_ok('Map::Tube::Plugin::FuzzyFind') || print "Bail out!\n";
}

diag( "Testing Map::Tube::Plugin::FuzzyFind $Map::Tube::Plugin::FuzzyFind::VERSION, Perl $], $^X" );

my $tube = new_ok( 'Sample' );
can_ok( $tube, 'fuzzy_find' );

