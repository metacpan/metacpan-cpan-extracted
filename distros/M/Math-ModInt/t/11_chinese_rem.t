# Copyright (c) 2009-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Tests of the Math::ModInt::ChineseRemainder utility module.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/11_chinese_rem.t'

#########################

use strict;
use warnings;
use Test;
BEGIN { plan tests => 76 };
use Math::BigInt;
use Math::ModInt qw(mod);
use Math::ModInt::ChineseRemainder qw(cr_combine cr_extract);
ok(1);

#########################

my $orig_size = Math::ModInt::ChineseRemainder->cache_size;
ok(4 < $orig_size);
my $cached = Math::ModInt::ChineseRemainder->cache_level;
ok(0 == $cached);

my $a = mod(42, 127);
ok($a);
ok($a->isa('Math::ModInt'));
ok(42 == $a);

my $b = mod(24, 128);
ok(24 == $b);
ok($b != $a);

my $c = cr_combine($a, $b);
ok($c);
ok($c->isa('Math::ModInt'));
ok(2328 == $c->residue);
ok(16256 == $c->modulus);
ok(42 == $c->residue % 127);
ok(24 == $c->residue % 128);

my $d = cr_extract($c, 127);
ok($d == $a);
my $e = cr_extract($c, 128);
ok($e == $b);

my $f = mod(32, 126);
my $g = mod(23, 129);
my $h = cr_combine($f, $g);
ok(32 == $h->residue % 126);
ok(23 == $h->residue % 129);

my $i = cr_extract($h, 126);
ok($i == $f);
my $j = cr_extract($h, 129);
ok($j == $g);

my $k = cr_combine($c, $h);
ok(44037504 == $k->modulus);
ok(-15587176 == $k->signed_residue);
ok(42 == $k->signed_residue % 127);
ok(24 == $k->signed_residue % 128);
ok(32 == $k->residue % 126);
ok(23 == $k->residue % 129);

$i = cr_extract($k, $k->modulus);
ok($i == $k);
$j = cr_extract($k, 129);
ok($j == $g);

my $size = Math::ModInt::ChineseRemainder->cache_size;
ok($orig_size == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(3 == $cached);

my $y0 = cr_combine();
ok(1 == $y0->modulus);
my $y1 = cr_combine($c);
ok($y1 == $c);
my $y4 = cr_combine($a, $b, $f, $g);
ok($y4 == $k);

my $m = mod(1, 10);
my $n = mod(11, 100);
my $o = mod(22, 100);
my $p = cr_combine($m, $n);
ok($p == $n);

my $q = cr_combine($m, $o);
ok(defined $q);
ok($q->isa('Math::ModInt'));
ok(!$q->is_defined);

my $level = Math::ModInt::ChineseRemainder->cache_level;
ok($cached < $level);
$size = Math::ModInt::ChineseRemainder->cache_resize($level+1);
ok($level+1 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok($level == $cached);
$size = Math::ModInt::ChineseRemainder->cache_resize($level);
ok($level == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok($level == $cached);
$size = Math::ModInt::ChineseRemainder->cache_resize(2);
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(2 == $cached);
$size = Math::ModInt::ChineseRemainder::cache_resize(4);
ok(4 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(2 == $cached);
$size = Math::ModInt::ChineseRemainder::cache_resize(2);
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(2 == $cached);

my $r = mod(2, 10);
my $s = cr_combine($r, $o);
ok($o == $s);

$size = Math::ModInt::ChineseRemainder->cache_size;
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(2 == $cached);

my $t = cr_combine($n, $o);
ok(!$t->is_defined);

$size = Math::ModInt::ChineseRemainder->cache_size;
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(2 == $cached);
$cached = Math::ModInt::ChineseRemainder->cache_flush;
ok(0 == $cached);
$size = Math::ModInt::ChineseRemainder->cache_size;
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_flush;
ok(0 == $cached);
$size = Math::ModInt::ChineseRemainder->cache_size;
ok(2 == $size);

my $u = cr_combine($n, $o);
ok(!$u->is_defined);

$size = Math::ModInt::ChineseRemainder->cache_size;
ok(2 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(1 == $cached);
$size = Math::ModInt::ChineseRemainder->cache_resize(0);
ok(0 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(0 == $cached);

my $v = cr_combine($n, $o);
ok(!$v->is_defined);

$size = Math::ModInt::ChineseRemainder->cache_size;
ok(0 == $size);
$cached = Math::ModInt::ChineseRemainder->cache_level;
ok(0 == $cached);

my $w = cr_extract($n, 100);
ok($w == $n);
my $x = cr_extract($n, 40);
ok(!$x->is_defined);

my $z1 = cr_combine($w, $x);
ok(!$z1->is_defined);

my $z2 = cr_extract($x, 127);
ok(!$z2->is_defined);

my $z3 = eval { cr_extract($w, -10) };
ok(!defined $z3);
ok($@ =~ /positive integer modulus expected/);

Math::ModInt::ChineseRemainder->cache_resize(100);

my $bi = Math::BigInt->new('1424788000964701366');
my @mp = map { mod($bi, $_) } (46337..46341);
my $ma = cr_combine(@mp);
ok($ma == $bi && !grep { $_ != $bi } @mp);
ok(!grep { cr_extract($ma, $_->modulus) != $_ } @mp);
my @mq = map { $_ ** 2 } @mp;
my $mb = cr_combine(@mq);
ok($ma ** 2 == $mb);
my $ms = cr_extract($ma, Math::BigInt->new('271'));
ok($ms->is_defined && 181 == $ms->residue && 271 == $ms->modulus);

__END__
