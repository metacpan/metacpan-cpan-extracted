#!/usr/bin/perl

use 5.006;
use strict; use warnings;
use lib 't/';
use Sample;
use Test::Map::Tube tests => 1;

ok_map(Sample->new);
