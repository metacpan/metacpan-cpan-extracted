#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 11;

use lib '../lib';
use Math::Polygon::Calc;

my @p = polygon_start_minxy [0,0], [1,1], [-2,1], [-2,-2], [0,0];
cmp_ok(scalar(@p),'==',5);
cmp_ok($p[0][0],'==',-2);
cmp_ok($p[0][1],'==',-2);
cmp_ok($p[1][0],'==',0);
cmp_ok($p[1][1],'==',0);
cmp_ok($p[2][0],'==',1);
cmp_ok($p[2][1],'==',1);
cmp_ok($p[3][0],'==',-2);
cmp_ok($p[3][1],'==',1);
cmp_ok($p[4][0],'==',-2);
cmp_ok($p[4][1],'==',-2);

