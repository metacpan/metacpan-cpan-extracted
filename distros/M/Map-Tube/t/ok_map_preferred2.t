#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Sample;
use Test::Map::Tube tests => 4;
use Test::More;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-preferred2.xml') );

use Data::Dumper;

my $ret = $map->get_shortest_route('S1', 'S4')->preferred( );
isa_ok( $ret, 'Map::Tube::Route' );
is( $ret, 'S1 (Line T), S2 (Line T), S3 (Line T), S4 (Line T)',
    'S1 - S4: preferred version' );

$ret = $map->get_shortest_route('S1', 'S5')->preferred();
isa_ok( $ret, 'Map::Tube::Route' );
is( $ret, 'S1 (Line T), S2 (Line T), S3 (Line T), S4 (Line S, Line T), S5 (Line S)',
    'S1 - S5: preferred version' );

done_testing;
