#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'This test requires Map::Tube::London';

my $tube = Map::Tube::London->new();
my ($diagram, $teststr);
eval { $diagram = $tube->as_png('Bakerloo'); };
is( $@, '' );
$teststr = substr( $diagram, 1, 3);
is( $teststr, 'PNG', 'PNG in binary format' );

eval { $diagram = $tube->as_png('Bakerloo', format => 'gv'); };
is( $@, '' );
$teststr = substr( $diagram, 0, 255);
like( $teststr, qr/^digraph\s/, 'GV format' );

done_testing;
