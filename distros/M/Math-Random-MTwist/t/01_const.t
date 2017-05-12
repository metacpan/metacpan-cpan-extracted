#!/usr/bin/perl

use strict;
use warnings;
use Math::Random::MTwist;
use Test::More tests => 4;

ok(ref MT_TIMESEED eq 'SCALAR', 'MT_TIMESEED');
ok(ref MT_FASTSEED eq 'SCALAR', 'MT_FASTSEED');
ok(ref MT_GOODSEED eq 'SCALAR', 'MT_GOODSEED');
ok(ref MT_BESTSEED eq 'SCALAR', 'MT_BESTSEED');
