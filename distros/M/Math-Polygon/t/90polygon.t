#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 36;

use lib '../lib';
use Math::Polygon;

my @p = ([0,0],[1,1],[0,2],[0,0]);
my @q = ([1,1],[0,2],[0,0],[1,1]);  # rotated left 1

# Instantiate from array
my $p = Math::Polygon->new(@p);
ok(defined $p);

isa_ok($p, 'Math::Polygon');
cmp_ok($p->nrPoints, '==', scalar(@p));
cmp_ok($p->order, '==', 3);    # triangle
cmp_ok($p->area, '==', 1);
ok(!$p->isClockwise);  # computed

my $p02 = $p->point(2);
ok(defined $p02,                  "got point");
cmp_ok($p02->[0], '==', 0);
cmp_ok($p02->[1], '==', 2);

my @p02 = $p->point(2);
cmp_ok(scalar(@p02), '==', 1,     "got one point");
cmp_ok($p02[0][0], '==', 0);
cmp_ok($p02[0][1], '==', 2);

# Instantiate by option
my $p2 = Math::Polygon->new(points => \@p, clockwise => 1);
ok(defined $p);

isa_ok($p2, 'Math::Polygon');
cmp_ok($p2->nrPoints, '==', scalar(@p));

ok($p2->isClockwise);   # specified, incorrect ;-)

# Instantiate by instance call
my $p3 = $p2->new(@q);

isa_ok($p3, 'Math::Polygon');
cmp_ok($p3->nrPoints, '==', scalar(@q));
ok($p3->isClockwise);   # specified, incorrect ;-)

my $p31 = $p3->point(1);
ok(defined $p31,                  "got point from q (not p)");
cmp_ok($p31->[0], '==', 0);
cmp_ok($p31->[1], '==', 2);

# Comparison

ok($p->equal(@p));
ok($p->same(@p));
ok(!$p->equal(@q));
ok($p->same(@q));

ok($p->startMinXY(@p));
my $q = Math::Polygon->new(@q);
ok($q->startMinXY(@p)->equal($p));

my @r = $p->lineClip(-1,-1,1,1);

cmp_ok(scalar(@r),'==',1);
my $r = shift @r;
cmp_ok(scalar(@$r),'==',3);
cmp_ok($r->[0][0],'==',0);
cmp_ok($r->[0][1],'==',1);
cmp_ok($r->[1][0],'==',0);
cmp_ok($r->[1][1],'==',0);
cmp_ok($r->[2][0],'==',1);
cmp_ok($r->[2][1],'==',1);

