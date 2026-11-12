#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Test::More;
use Sample;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-line-change.xml') );

my $ret = $map->get_all_routes('S1', 'S4');

isa_ok( $ret, 'ARRAY' );
isa_ok( $_, 'Map::Tube::Route' ) for @$ret;
is_deeply( $ret,
    [ 'S1 (Line P), S2 (Line P, Line Q), S3 (Line P), S4 (Line P, Line Q)',
      'S1 (Line P), S2 (Line P, Line Q), X1 (Line Q), S4 (Line P, Line Q)',
    ]
   );

done_testing;
