#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Test::More;
use Sample;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-sample.xml') );

my $ret = $map->get_stations();
isa_ok($ret, 'ARRAY');
$ret = [sort @$ret];
is_deeply($ret, [ "A1 (A)", "A2 (A)", "A3 (A, B)", "B1 (A, B)", "B2 (B)" ]);

$ret = $map->get_stations('A');
isa_ok($ret, 'ARRAY');
$ret = [sort @$ret];
is_deeply($ret, [ "A1 (A)", "A2 (A)", "A3 (A, B)", "B1 (A, B)" ]);

$ret = $map->get_next_stations('A3');
isa_ok($ret, 'ARRAY');
$ret = [sort @$ret];
is_deeply($ret, [ "A2 (A)", "B1 (A, B)" ]);

$ret = $map->get_linked_stations('A3');
isa_ok($ret, 'ARRAY');
$ret = [sort @$ret];
is_deeply($ret, [ "A2", "B1" ]);

done_testing;
