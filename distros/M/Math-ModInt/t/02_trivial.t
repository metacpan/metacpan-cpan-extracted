# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::Trivial subclass of Math::ModInt.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/02_trivial.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 38 };
use Math::ModInt qw(mod divmod);

#########################

my $a = mod(0, 1);
ok(defined $a);
ok($a->isa('Math::ModInt'));
ok(0 == $a->residue);
ok(1 == $a->modulus);
ok(0 == $a->signed_residue);
ok(0 == $a->centered_residue);
ok('mod(0, 1)' eq "$a");
ok($a->is_defined);
ok(!$a->is_undefined);

my $b = $a->new(0);
ok($a == $b);
ok(not $a != $b);
ok(!$a);
ok($a? 0: 1);

my $c = -$a;
ok($c == $a);
my $d = $a->inverse;
ok($d == $a);
my $e = $a + $b;
ok($e == $a);
my $f = $a - $b;
ok($f == $a);
my $g = $a * $b;
ok($g == $a);
my $h = $a / $b;
ok($h == $a);
my $i = $a ** 3;
ok($i == $a);
my $j = $a ** 0;
ok($j == $a);
my $k = $a ** -1;
ok($k == $a);

my $el = $a + 1;
ok($el == $a);
my $er = 1 + $a;
ok($er == $a);
my $fl = $a - 1;
ok($fl == $a);
my $fr = 1 - $a;
ok($fr == $a);
my $gl = $a * 2;
ok($gl == $a);
my $gr = 2 * $a;
ok($gr == $a);
my $hl = $a / 2;
ok($hl == $a);
my $hr = 2 / $a;
ok($hr == $a);

my $il = eval { $a ** $b };
ok(!defined $il);
ok($@ =~ /integer exponent expected/);
my $ir = eval { 1 ** $a };
ok(!defined $ir);
ok($@ =~ /integer exponent expected/);

my ($q, $r) = divmod(47, 1);
ok(47 == $q);
ok($r->isa('Math::ModInt'));
ok(0 == $r->residue);
ok(1 == $r->modulus);

__END__
