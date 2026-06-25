#!/usr/bin/env perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use lib 't/';
use File::Spec;
use Test::More;
use Sample;

my $map = Sample->new( xml => File::Spec->catfile('t', 'map-sample.xml') );

my $ret = $map->get_lines();
isa_ok($ret, 'ARRAY');
$ret = [sort @$ret];
is_deeply($ret, ['A', 'B']);

done_testing;
