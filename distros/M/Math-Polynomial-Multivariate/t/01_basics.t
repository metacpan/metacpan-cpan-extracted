# Copyright (c) 2013-2014 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01_basics.t 17 2014-02-21 12:51:52Z demetri $

# Checking basic constructors and attribute accessors.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/01_basics.t'

#########################

use strict;
use warnings;
use Test::More tests => 47;
use Math::Polynomial::Multivariate;
ok(1);                                  # 1

#########################

use constant MPM => Math::Polynomial::Multivariate::;

my $one = MPM->const(1);
isa_ok($one, MPM);                      # 2
is("$one", '1');                        # 3

my $two = $one->const(2);
isa_ok($two, MPM);                      # 4
is("$two", '2');                        # 5

my $x = MPM->var('x');
isa_ok($x, MPM);                        # 6
is("$x", 'x');                          # 7

my $y = $one->var('y');
isa_ok($y, MPM);                        # 8
is("$y", 'y');                          # 9

my $zero = MPM->null;
isa_ok($zero, MPM);                     # 10
is("$zero", '0');                       # 11

$zero = $one->const(0);
isa_ok($zero, MPM);                     # 12
is("$zero", '0');                       # 13

my $null = $one->null;
isa_ok($null, MPM);                     # 14
is("$null", '0');                       # 15

my $p = MPM->monomial(3, { 'x' => 1, 'y' => 2 });
isa_ok($p, MPM);                        # 16
is("$p", "3*x*y^2");                    # 17

my $q = $one->monomial(1, { 'x' => 2 });
isa_ok($q, MPM);                        # 18
is("$q", "x^2");                        # 19

my $qq = $one->monomial(1, { 'x' => 2, 'y' => 0 });
isa_ok($qq, MPM);                       # 20
is("$qq", "x^2");                       # 21

my $r = $one->monomial(0, { 'z' => 1 });
isa_ok($r, MPM);                        # 22
is("$r", '0');                          # 23

$r = $one->monomial(2, { 'x' => 0 });
isa_ok($r, MPM);                        # 24
is("$r", '2');                          # 25

$r = eval { $one->monomial(3, { 'x' => -1 }) };
is($r, undef);                          # 26
like($@, qr/^hash of integer exponents expected/);  # 27

my @v = $one->variables;
is("@v", q[]);                          # 28

@v = $p->variables;
is("@v", 'x y');                        # 29

my @e = $p->exponents_of('x');
is("@e", '1');                          # 30

my $f = $p->factor_of('x', 1);
isa_ok($f, MPM);                        # 31
is("$f", '3*y^2');                      # 32

my $g = $p->factor_of('y', 1);
isa_ok($g, MPM);                        # 33
is("$g", '0');                          # 34

my $h = $p->factor_of('z', 0);
isa_ok($h, MPM);                        # 35
is("$h", '3*x*y^2');                    # 36

is($f->is_null, !1);                    # 37
is($f->is_not_null, !0);                # 38

is($g->is_null, !0);                    # 39
is($g->is_not_null, !1);                # 40

is($p->number_of_terms, 1);             # 41
is($null->number_of_terms, 0);          # 42

is($p->degree, 3);                      # 43
ok($null->degree < -999999999);         # 44

my $mp = $p->multidegree;
is_deeply($mp, {'x' => 1, 'y' => 2});   # 45

my $mz = $null->multidegree;
is_deeply($mz, {});                     # 46

my $m2 = $two->multidegree;
is_deeply($m2, {});                     # 47

__END__
