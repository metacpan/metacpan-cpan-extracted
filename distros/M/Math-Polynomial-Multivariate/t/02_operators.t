# Copyright (c) 2013-2014 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02_operators.t 17 2014-02-21 12:51:52Z demetri $

# Checking operators.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02_operators.t'

#########################

use strict;
use warnings;
use Test::More tests => 57;
use Math::Polynomial::Multivariate;

#########################

use constant MPM => Math::Polynomial::Multivariate::;

my $two   = MPM->const(2);
my $zero  = $two->null;
my $x     = $two->var('x');
my $y     = $two->var('y');
my $two_x = $two * $x;

my $p = -$two + $x ** 2 + $x * $y - $y ** 3;
isa_ok($p, MPM);                        # 1
is("$p", "-2 + x^2 + x*y + -1*y^3");    # 2
my $q = ($x + $y) * ($x - $y);
isa_ok($q, MPM);                        # 3
is("$q", "x^2 + -1*y^2");               # 4
my $r = $q ** 0;
isa_ok($r, MPM);                        # 5
is("$r", "1");                          # 6
my $s = $q - $q;
isa_ok($s, MPM);                        # 7
is("$s", "0");                          # 8
my $t = $x + $two_x;
isa_ok($t, MPM);                        # 9
is("$t", "3*x");                        # 10

my $v0 = $s->evaluate({});
is(ref($v0), q[]);                      # 11
is("$v0", '0');                         # 12
my $v1 = $p->evaluate({'x' => 1, 'y' => 2});
is(ref($v1), q[]);                      # 13
is("$v1", '-7');                        # 14
my $v3 = eval { $p->evaluate({'x' => 1}) };
is($v3, undef);                         # 15
like($@, qr/^missing variable: y/);     # 16
my $v4 = eval { $p->evaluate({'u' => 0}) };
is($v4, undef);                         # 17
like($@, qr/^missing variables: x y/);  # 18

my $u = $p->subst('y', $two_x);
isa_ok($u, MPM);                        # 19
is("$u", "-2 + 3*x^2 + -8*x^3");        # 20
my $v = $p->subst('z', $q);
isa_ok($v, MPM);                        # 21
is("$v", "-2 + x^2 + x*y + -1*y^3");    # 22
my $w = $zero->subst('x', $x);
isa_ok($w, MPM);                        # 23
is("$w", '0');                          # 24

is($x == $y, q[]);                      # 25
is($x != $y, 1);                        # 26
is($x == $p, q[]);                      # 27
is($x != $p, 1);                        # 28
is($x == $two_x, q[]);                  # 29
is($x != $two_x, 1);                    # 30
is($x == $x, 1);                        # 31
is($x != $x, q[]);                      # 32

my $m  = $x*$y**2 + $x**2*$y;
my $md = $m->multidegree;
is_deeply($md, {'x' => 2, 'y' => 2});   # 33

my $n = ((($x + $two) * $x + $two) * $x + $two) * $x + $two;
is($n->degree, 4);                      # 34

my $o;
$o = eval { $x ** 0.5 };
is($o, undef);                          # 35
like($@, qr/^illegal exponent/);        # 36

$o = eval { 2 ** $x };
is($o, undef);                          # 37
like($@, qr/illegal exponent/);         # 38

$o = $x + 2;
isa_ok($o, MPM);                        # 39
is("$o", '2 + x');                      # 40

$o = $x - 2;
isa_ok($o, MPM);                        # 41
is("$o", '-2 + x');                     # 42

$o = 2 - $x;
isa_ok($o, MPM);                        # 43
is("$o", '2 + -1*x');                   # 44

$o = $x * 2;
isa_ok($o, MPM);                        # 45
is("$o", '2*x');                        # 46

$o = $x == 1;
is("$o", !1);                           # 47

$o = $x != 1;
is("$o", !0);                           # 48

my $px = $p->partial_derivative('x');
is("$px", "2*x + y");                   # 49
my $casted = 0;
my $py = $p->partial_derivative('y', sub { ++$casted; $_[0] });
is("$py", "x + -3*y^2");                # 50
is($casted, 2);                         # 51

my @vars = $p->variables;
is("@vars", "x y");                     # 52

my $c;
$c = $p->coefficient({});
is($c, -2);                             # 53

$c = $p->coefficient({x => 3});
is($c, 0);                              # 54

$c = $p->coefficient({z => 1});
is($c, 0);                              # 55

$c = $p->coefficient({x => 1, y => 1});
is($c, 1);                              # 56

my $pp = 2*$x - $x - $x - 2*$y + $y + $y;
is("$pp", "0");                         # 57

__END__
