#!/usr/bin/perl -w
#                              -*- Mode: Perl -*- 
# $Basename$
# $Revision: 1.3 $
# Author          : Ulrich Pfeifer
# Created On      : Mon Apr 16 11:12:57 2001
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Wed Oct 24 09:30:58 2001
# Language        : CPerl
# 
# (C) Copyright 2001, UUNET Deutschland GmbH, Germany
# 

use strict;
use Test;
BEGIN { plan tests => 12};

use Math::Matrix;

my $A = new Math::Matrix ([rand,rand,rand],
                          [rand,rand,rand],
                          [rand,rand,rand]);

my $B = $A->multiply_scalar(-2);

ok($B);

my $C = $A->add($B)->multiply_scalar(-1);

ok($C->equal($A));

my $l = $A->slice(0);
my $R = $A->slice(1,2);
my $D = $l->concat($R);

ok($D->equal($A));

my $v = new Math::Matrix ([rand,rand,rand]);
my $M = $A->concat($v->transpose);
my $x = $M->solve;

my $d = $A->determinant;
my $F = $v->transpose->concat($R);
my $e = $F->determinant;

#$x->transpose->print("The solution x");

ok(abs($e/$d-$x->[0][0]) < 0.000001);

ok(abs($A->transpose->slice(0)->dot_product($x)-$v->[0][0]) < 0.000001);

ok($x->absolute);

ok(abs($x->normalize->absolute-1) < 0.000001);

my $t = $R->transpose->cross_product();
ok($t);
my $o = $t->multiply($R);
ok($o->absolute < 0.000001);

my $E = Math::Matrix->new_identity(3);
my $G = $A->multiply($E);
ok($A->equal($G));

my $Ai = $A->invert;
my $P  = $A->multiply($Ai);
ok($P->equal($E));

my $Z = new Math::Matrix ([0,0,0],
                          [0,0,0],
                          [0,0,0]);
my $Q=$Z->subtract($P);
my $J=-$Q;
ok($J->equal($P));
