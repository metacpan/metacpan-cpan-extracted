#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 16;

use lib '../lib';
use Math::Polygon::Surface;

my @p = ([0,0],[1,1],[0,2],[0,0]);
my @q = ([1,1],[0,2],[0,0],[1,1]);  # rotated left 1

# Instantiate from array
my $s = Math::Polygon::Surface->new(\@p);

ok(defined $s);
isa_ok($s, 'Math::Polygon::Surface');

my $p = $s->outer;
ok(defined $p);
isa_ok($p, 'Math::Polygon');
cmp_ok($p->nrPoints, '==', 4);

my @i = $s->inner;
cmp_ok(scalar(@i), '==', 0);

# With inner
my $s2 = Math::Polygon::Surface->new(\@p, \@q, \@q);
ok(defined $s2);
isa_ok($s2, 'Math::Polygon::Surface');

my $p2 = $s2->outer;
ok(defined $p2);
isa_ok($p2, 'Math::Polygon');
cmp_ok($p2->nrPoints, '==', 4);

my @i2 = $s2->inner;
cmp_ok(scalar(@i2), '==', 2);
isa_ok($i2[0], 'Math::Polygon');
cmp_ok($i2[0]->nrPoints, '==', 4);
isa_ok($i2[1], 'Math::Polygon');
cmp_ok($i2[1]->nrPoints, '==', 4);
