# Copyright (c) 2019-2022 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 03_algebra.t'

use strict;
use warnings;
use Math::ModInt qw(mod);
use Math::Polynomial::ModInt qw(modpoly);

use Test::More tests => 38;

sub display {
    my ($tag, $list) = @_;
    diag join q[ ], "$tag:", map { $_->index } @{$list};
}

sub ldump {
    my ($tag, $list) = @_;
    my $i = 0;
    foreach my $p (@{$list}) {
        my $x = $p->index;
        diag $tag . "[$i] = $p #$x\n";
        ++$i;
    }
}

sub modint_equal {
    my ($this, $that) = @_;
    my $qthat = $that->as_string;
    if (!defined $this) {
        diag(qq{got undef, expected $qthat});
        return 0;
    }
    if (!ref($this) || !$this->isa('Math::ModInt')) {
        diag(qq{got "$this", expected $qthat});
        return 0;
    }
    if ($this->is_undefined) {
        diag(qq{got an undefined ModInt, expected $qthat});
        return 0;
    }
    if ($this != $that) {
        my $qthis = $this->as_string;
        diag(qq{got $qthis, expected $qthat});
        return 0;
    }
    return 1;
}

$| = 1;

my $q1  = modpoly(5, 3);
my $q1m = $q1->monize;
ok($q1m == $q1);

my $q2  = modpoly(7, 3);
my $q2m = $q2->monize;
ok($q2m == $q1);

my $q3  = modpoly(9, 4);
my $q3m = eval { $q3->monize };
ok(!defined $q3m);
like($@, qr/^undefined inverse/);

my $q4  = modpoly(0, 3);
my $q4m = $q4->monize;
ok($q4m == $q4);
my $q4i = $q4->is_monic;
ok(!$q4i);

my $p = modpoly(265, 3);
my $z = $p->first_root;
ok(!defined $z);

my $m = $p->is_irreducible;
ok($m);

my $r1  = modpoly(131, 3);
my $r1r = $r1->first_root;
ok(modint_equal($r1r, mod(2, 3)));

my $r2  = modpoly(5, 5);
my $r2r = $r2->first_root;
ok(modint_equal($r2r, mod(0, 5)));

my $r3  = modpoly(9, 5);
my $r3r = $r3->first_root;
ok(modint_equal($r3r, mod(1, 5)));

my $r4  = modpoly(13, 5);
my $r4r = $r4->first_root;
ok(modint_equal($r4r, mod(1, 5)));

my $r5  = modpoly(21, 5);
my $r5r = $r5->first_root;
ok(modint_equal($r5r, mod(1, 5)));

my $c = $r1->is_irreducible;
ok(!$c);

my $f1 = $r1->lambda_reduce(2);
is($f1->centerlift->as_string, '(- x - 1)');

my $f2 = $f1->lambda_reduce(2);
ok($f1 == $f2);

ok(!modpoly(  1, 3)->is_irreducible);
ok( modpoly(  4, 3)->is_irreducible);
ok(!modpoly( 12, 3)->is_irreducible);
ok( modpoly( 14, 3)->is_irreducible);
ok(!modpoly( 16, 3)->is_irreducible);
ok( modpoly( 19, 2)->is_irreducible);
ok(!modpoly( 19, 3)->is_irreducible);
ok(!modpoly( 82, 3)->is_irreducible);
ok( modpoly( 86, 3)->is_irreducible);
ok(!modpoly(782, 3)->is_irreducible);
ok(modpoly(103874, 47)->is_irreducible);
ok(modpoly(148935, 53)->is_irreducible);

my $e1 = eval { modpoly(17, 4)->is_irreducible };
ok(!defined $e1);
like($@, qr/^modulus not prime/);

my $e2 = eval { modpoly(261, 4)->is_irreducible };
ok(!defined $e2);
like($@, qr/^modulus not prime/);

my $e3 = eval { Math::Polynomial::ModInt->new };
ok(!defined $e3);
like($@, qr/^insufficient arguments/);

my $e4 = eval { modpoly(0, 2)->new };
ok(defined $e4);
is($e4->as_string, '(0 (mod 2))');

my @xv = (mod(0, 4), mod(2, 4));
my @yv = (mod(1, 4), mod(3, 4));
my $e5 = eval { Math::Polynomial::ModInt->interpolate(\@xv, \@yv) };
ok(!defined $e5);
like($@, qr/^modulus not prime/);

__END__
