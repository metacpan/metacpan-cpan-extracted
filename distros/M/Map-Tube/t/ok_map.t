#!/usr/bin/env perl

use v5.14;
use strict;
use warnings;
use lib 't/';
use Sample;
use Test::Map::Tube tests => 1;

ok_map(Sample->new);
