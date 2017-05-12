#!/usr/bin/perl -w
#                              -*- Mode: Perl -*- 

use strict;
use Test;
BEGIN { plan tests => 8};

use Math::Matrix;

my $p = Math::Matrix->diagonal(1, 4, 4, 8);
my $q = Math::Matrix->diagonal([1, 4, 4, 8]);
my $r = Math::Matrix->tridiagonal([1, 4, 4, 8]);
my $s = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15]);
my $t = Math::Matrix->tridiagonal([1, 4, 4, 8], [9, 12, 15], [4, 3, 2]);
my $u = Math::Matrix->tridiagonal([1, 4, 4, 8], [1, 1, 1], [1, 1, 1]);

ok($p);
ok($q);
ok($r);
ok($s);
ok($t);
ok($p->equal($q));
ok(Math::Matrix->new($r->diagonal_vector())->equal(Math::Matrix->new([1, 4, 4, 8])));
ok($u->equal($r));
