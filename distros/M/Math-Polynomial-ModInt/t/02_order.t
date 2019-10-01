# Copyright (c) 2019 by Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 02_order.t'

use strict;
use warnings;
use Math::Polynomial::ModInt        qw(modpoly);
use Math::Polynomial::ModInt::Order qw($BY_INDEX $CONWAY $SPARSE);

use Test::More tests => 37;

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

my $p = modpoly(27, 3);
my @ei = ();
while ($p->degree == 3) {
    push @ei, $p;
    $p = $BY_INDEX->next_poly($p);
}
my @oi = sort $BY_INDEX @ei;
# display('ei', \@ei);
# display('oi', \@oi);
is_deeply \@oi, \@ei;

$p = modpoly(27, 3);
my @ec = ();
while ($p->degree == 3) {
    push @ec, $p;
    $p = $CONWAY->next_poly($p);
}
my @oc = sort $CONWAY @ec;
# display('ec', \@ec);
# display('oc', \@oc);
is_deeply \@oc, \@ec;

$p = modpoly(0, 3);
my @es = ();
while ($p->degree <= 3) {
    push @es, $p;
    $p = $SPARSE->next_poly($p);
}
my @os = sort $SPARSE @es;
# display('es', \@es);
# display('os', \@os);
is_deeply \@os, \@es;

my @indexes = (0 .. 3, 3 .. 6);
my @moduli  = 2 .. 4;
my @mixed = map {
    my $i = $_;
    map { modpoly($i, $_) } @moduli
} @indexes;
my @wanted = map {
    my $m = $_;
    map { modpoly($_, $m) } @indexes
} @moduli;
my @sorted = sort $BY_INDEX @mixed;
# ldump('sorted', \@sorted);
is_deeply(\@sorted, \@wanted);

my @both = (modpoly(2, 2), modpoly(3, 3));
foreach my $p1 (@both) {
    foreach my $p2 (@both) {
        my $cmp = $p1->modulus <=> $p2->modulus;
        is($BY_INDEX->cmp($p1, $p2), $cmp);
        is($BY_INDEX->eq($p1, $p2), $cmp == 0);
        is($BY_INDEX->ne($p1, $p2), $cmp != 0);
        is($BY_INDEX->lt($p1, $p2), $cmp <  0);
        is($BY_INDEX->le($p1, $p2), $cmp <= 0);
        is($BY_INDEX->gt($p1, $p2), $cmp >  0);
        is($BY_INDEX->ge($p1, $p2), $cmp >= 0);
    }
}

@indexes = (12 .. 14, 14 .. 16);
@moduli  = 3 .. 4;
@mixed = map {
    my $i = $_;
    map { modpoly($i, $_) } @moduli
} @indexes;
@wanted = (
    modpoly(15, 3),
    modpoly(16, 3),
    modpoly(12, 3),
    modpoly(13, 3),
    modpoly(14, 3),
    modpoly(14, 3),
    modpoly(12, 4),
    modpoly(15, 4),
    modpoly(14, 4),
    modpoly(14, 4),
    modpoly(13, 4),
    modpoly(16, 4),
);
@sorted = sort $CONWAY @mixed;
# ldump('sorted', \@sorted);
is_deeply(\@sorted, \@wanted);

@indexes = (20 .. 22, 22 .. 24);
@moduli  = 3 .. 4;
@mixed = map {
    my $i = $_;
    map { modpoly($i, $_) } @moduli
} @indexes;
@wanted = (
    modpoly(20, 3),
    modpoly(21, 3),
    modpoly(24, 3),
    modpoly(22, 3),
    modpoly(22, 3),
    modpoly(23, 3),
    modpoly(20, 4),
    modpoly(24, 4),
    modpoly(21, 4),
    modpoly(22, 4),
    modpoly(22, 4),
    modpoly(23, 4),
);
@sorted = sort $SPARSE @mixed;
# ldump('sorted', \@sorted);
is_deeply(\@sorted, \@wanted);

my ($p1, $p2, $p3) =
    map {
        Math::Polynomial->new(modpoly($_, 3)->coefficients)
    } 11, 12, 15;
is_deeply($BY_INDEX->next_poly($p1), $p2);
is_deeply($CONWAY->next_poly($p1), $p3);
is_deeply($SPARSE->next_poly($p2), $p3);
