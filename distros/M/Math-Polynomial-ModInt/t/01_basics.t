# Copyright (c) 2019-2022 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01_basics.t'

use strict;
use warnings;
use Math::BigInt try => 'GMP';
use Math::ModInt qw(mod);
use Math::Polynomial::ModInt qw(modpoly);

use Test::More tests => 52;

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

$| = 1;

my $p1 = modpoly(265, 3);
isa_ok($p1, 'Math::Polynomial::ModInt');
isa_ok($p1, 'Math::Polynomial');
is($p1->as_string, '(x^5 + 2*x^2 + x + 1 (mod 3))');
is($p1->index, 265);
is($p1->modulus, 3);
is($p1->degree, 5);
is($p1->number_of_terms, 4);
ok($p1->evaluate(mod(1, 3)) == mod(2, 3));

my $p2 = Math::Polynomial::ModInt->from_index(265, 3);
isa_ok($p2, 'Math::Polynomial::ModInt');
isa_ok($p2, 'Math::Polynomial');
is($p2->as_string, '(x^5 + 2*x^2 + x + 1 (mod 3))');
is($p2->index, 265);
is($p2->modulus, 3);

my $p3 = Math::Polynomial::ModInt->new(
    mod(1, 3), mod(1, 3), mod(2, 3), mod(0, 3), mod(0, 3), mod(1, 3)
);
isa_ok($p3, 'Math::Polynomial::ModInt');
isa_ok($p3, 'Math::Polynomial');
is($p3->as_string, '(x^5 + 2*x^2 + x + 1 (mod 3))');
is($p3->index, 265);
is($p3->modulus, 3);

my $p4 = $p1->lift;
isa_ok($p4, 'Math::Polynomial');
ok(!$p4->isa('Math::Polynomial::ModInt'));
is($p4->as_string, '(x^5 + 2*x^2 + x + 1)');
is($p4->degree, 5);
is($p4->coeff(0), 1);
ok($p4->evaluate(1) == 5);

my $p5 = $p1->centerlift;
isa_ok($p5, 'Math::Polynomial');
ok(!$p5->isa('Math::Polynomial::ModInt'));
is($p5->as_string, '(x^5 - x^2 + x + 1)');
is($p5->degree, 5);
is($p5->coeff(0), 1);
ok($p5->evaluate(1) == 2);

Math::Polynomial::ModInt->string_config({
    prefix => q[],
    suffix => q[],
    wrap => sub {
        my ($p) = @_;
        my $x = $p->index;
        my $m = $p->modulus;
        return "modpoly($x, $m)";
    },
});
is($p1->as_string, 'modpoly(265, 3)');

my $p6 = $p1->from_index(266);
is($p6->as_string, 'modpoly(266, 3)');

my $p7 = eval { Math::Polynomial::ModInt->from_index(267) };
ok(!defined $p7);
like($@, qr/usage error: modulus parameter missing/);

my $p8 = Math::Polynomial::ModInt->from_int_poly($p4, 3);
is($p8->as_string, 'modpoly(265, 3)');

my $p9 = $p1->from_int_poly($p5);
ok($p8 == $p9);

$p7 = eval { Math::Polynomial::ModInt->from_int_poly($p5) };
ok(!defined $p7);
like($@, qr/usage error: modulus parameter missing/);

ok($p1->is_equal($p2));
ok(!$p1->is_unequal($p2));
ok(!modpoly(0, 2)->is_equal(modpoly(0, 3)));
ok(modpoly(0, 2)->is_unequal(modpoly(0, 3)));
ok(!modpoly(1, 2)->is_equal(modpoly(2, 2)));
ok(modpoly(1, 2)->is_unequal(modpoly(2, 2)));
ok(!modpoly(2, 2)->is_equal(modpoly(3, 2)));
ok(modpoly(2, 2)->is_unequal(modpoly(3, 2)));
ok(!modpoly(5, 2)->is_equal(modpoly(6, 2)));
ok(modpoly(5, 2)->is_unequal(modpoly(6, 2)));

$p7 = eval { Math::Polynomial::ModInt->new(mod(0, 1)) };
ok(!defined $p7);
like($@, qr/modulus must be greater than one/);

$p7 = eval { Math::Polynomial::ModInt->from_index(1, 1) };
ok(!defined $p7);
like($@, qr/modulus must be greater than one/);

