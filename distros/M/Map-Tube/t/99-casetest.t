#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use lib 't/';
use File::Spec;
use Sample;
use Test::Map::Tube tests => 1;

my $map = Sample->new( xml => File::Spec->catfile('t', 'casetest.xml') );
ok_map_functions($map);
