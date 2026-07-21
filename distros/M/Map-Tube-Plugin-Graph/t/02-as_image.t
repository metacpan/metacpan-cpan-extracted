#!/usr/bin/perl
use 5.014;
use strict;
use warnings FATAL => 'all';
use Test::More;

eval {require Map::Tube::London; 1} or plan skip_all => 'This test requires Map::Tube::London';

my $tube = Map::Tube::London->new();
my ($diagram, $teststr);
eval { $diagram = $tube->as_image(); };
is( $@, '' );
$teststr = substr( $diagram, 0, 5);
is( $teststr, 'iVBOR', 'PNG in base64 format' );

eval { $diagram = $tube->as_image('Bakerloo'); };
is( $@, '' );
$teststr = substr( $diagram, 0, 5);

done_testing;
