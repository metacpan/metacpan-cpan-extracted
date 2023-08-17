# Copyright (c) 2022-2023 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 07_principals.t'

#########################

use strict;
use warnings;
use File::Spec;
use FindBin;
use Config;
use Math::DifferenceSet::Planar;
use constant MDP => Math::DifferenceSet::Planar::;

use Test::More;
if (MDP->can('plane_principal_elements')) {
    plan tests => 94;
}
else {
    plan skip_all => 'principal elements not yet implemented';
}

#########################

my $ARITH_BITS = int 1.5+log(~0 >> 1)/log(2);

my $ds = MDP->new(16);
my $dz = $ds->zeta_canonize;
isa_ok($dz, MDP);

is($dz->zeta,  0, 'zeta-canonical zeta');
is($dz->eta,   0, 'zeta-canonical eta');
is($dz->theta, 0, 'zeta-canonical theta');

my $it = $ds->iterate_planes_zc;
is(ref($it), 'CODE', 'iterate planes using zeta-canonical sets');

my $di = $it->();
is($di->compare($dz), 0, 'first set');

$di = $it->();
is($di->zeta,  0, 'second set zeta');
is($di->eta,   0, 'second set eta');
is($di->theta, 0, 'second set theta');

my $c = 2;
while ($it->()) {
    ++$c;
}
is($c, 12, 'number of iterations');

my $lr = MDP->lex_reference(3);
SKIP: {
    skip "lex reference unknown", 3 if !defined $lr;
    is($lr->start_element, 0, 'lex reference');
    $lr = MDP->lex_reference(3, 1);
    is($lr->start_element, 0, 'lex reference with power');
    $lr = eval { MDP->lex_reference(127, 111) };
    is($lr, undef, 'no huge lex reference');
}

my $gr = MDP->gap_reference(3);
SKIP: {
    skip "gap reference unknown", 3 if !defined $gr;
    my ($e1, $e2) = $gr->largest_gap;
    is($e2, 0, 'gap reference');
    $gr = MDP->gap_reference(3, 1);
    ($e1, $e2) = $gr->largest_gap;
    is($e2, 0, 'gap reference with power');
    $gr = eval { MDP->gap_reference(127, 111) };
    is($gr, undef, 'no huge gap reference');
}

my $zr = MDP->std_reference(2);
SKIP: {
    skip "zeta reference unknown", 6 if !defined $zr;
    my $t = $zr->theta;
    is($t, 0, 'zeta reference theta');
    my $l = $zr->lambda;
    is($l, 1, 'zeta reference lambda');
    $zr = MDP->std_reference(2, 1);
    $t = $zr->theta;
    is($t, 0, 'zeta reference with power theta');
    $l = $zr->lambda;
    is($l, 1, 'zeta reference with power lambda');
    $zr = eval { MDP->std_reference(127, 111) };
    is($zr, undef, 'no huge zeta reference');
    $zr = MDP->known_std_ref(4, 2);
    is($zr, !1, 'no nonprime zeta reference');
}

my $nr = MDP->from_elements_fast(3, 4, 6);
is($nr->theta, 2, 'theta w/o reference');
is($nr->lambda, undef, 'no lambda w/o reference');

my @pe = $nr->plane_principal_elements;
is("@pe", '1', 'principal elements');

my @se = $nr->plane_supplemental_elements;
is("@se", '', 'supplemental elements');

my @fe = $ds->plane_fill_elements;
is("@fe", "91 182", 'fill elements');

my @de = sort { $a <=> $b } $nr->plane_derived_elements_of(@pe, @se);
is("@de", '2 4', 'derived elements');

my $ds2 = eval { MDP->from_lambda(6, 1) };
is($ds2, undef, 'no from_lambda non-prime-power order');
like($@, qr/^this implementation cannot handle order 6/);

$ds2 = eval { MDP->from_lambda(4, 3) };
is($ds2, undef, 'no from_lambda lambda and modulus not coprime');
like($@, qr/^impossible lambda value 3/);

$ds2 = eval { MDP->from_lambda(3, 5) };
is($ds2, undef, 'no from_lambda lambda non-canonical');
like($@, qr/^non-canonical lambda value 5/);

$ds2 = eval { MDP->from_lambda(3, 2, -1) };
is($ds2, undef, 'no from_lambda theta negative');
like($@, qr/^non-canonical theta value -1/);

$ds2 = eval { MDP->from_lambda(3, 2, 13) };
is($ds2, undef, 'no from_lambda theta too large');
like($@, qr/^non-canonical theta value 13/);

$ds2 = eval { MDP->from_lambda(3, 2) };
if (defined $ds2) {
    my @e = $ds2->elements_sorted;
    is("@e", '0 2 5 6', 'from_lambda w/o delta');
}
else {
    like($@, qr/^reference set of order 3 not available/, 'no ref');
}

$ds2 = eval { MDP->from_lambda(3, 2, 1) };
if (defined $ds2) {
    my @e = $ds2->elements_sorted;
    is("@e", '1 3 6 7', 'from_lambda with delta');
}
else {
    like($@, qr/^reference set of order 3 not available/, 'no ref');
}

my $ref19 = MDP->std_reference(19);
SKIP: {
    skip 'reference set of order 19 not available', 6 if !defined $ref19;
    my $ds1 = MDP->from_lambda(19, 179, 29);
    my @p = $ds1->plane_principal_elements;
    my @s = $ds1->plane_supplemental_elements;
    my @f = $ds1->plane_fill_elements;
    is("@p", '65 179 199', 'principal elements order 19');
    is("@s", '39 48 87', 'supplemental elements order 19');
    is("@f", '127 254', 'fill elements order 19');
    my $ds2 = $ds1->multiply(182);
    @p = $ds2->plane_principal_elements;
    @s = $ds2->plane_supplemental_elements;
    @f = $ds2->plane_fill_elements;
    is("@p", '1 23 193', 'principal elements multiplied');
    is("@s", '153 159 213', 'supplemental elements multiplied');
    is("@f", '127 254', 'fill elements multiplied');
}

$ds2 = eval { MDP->from_lambda(2147483647, 1) };
is($ds2, undef, 'no from_lambda huge modulus');
if ($ARITH_BITS < 64) {
    like(
        $@, qr/^order 2147483647 too large for this platform/,
        "no huge ref $ARITH_BITS bits"
    );
}
else {
    like(
        $@, qr/^reference set of order 2147483647 not available/,
        'no huge ref'
    );
}

SKIP: {
    my $db    = File::Spec->catfile($FindBin::Bin, 'db', 'extra.db');
    my $count = eval { MDP->set_database($db) };
    skip 'test database not regognized', 44 if !$count;
    my $ds    = eval { MDP->new(11) };
    ok(defined($ds), 'found test record 11');
    my $sds   = MDP->std_reference(11);
    ok(defined($sds), , 'test record has zeta reference');
    $ds       = eval { MDP->new(13) };
    ok(defined($ds), 'found test record 13');
    $sds      = MDP->std_reference(13);
    is($sds, undef, 'test record has no zeta reference');
    ok(MDP->known_std_ref(11), 'std ref known');
    ok(!MDP->known_std_ref(0), 'zero std ref checked');
    ok(!MDP->known_std_ref(13), 'unknown std ref checked');
    ok(!MDP->known_std_ref(16), 'too large std ref checked');
    is(MDP->known_std_ref_min_order, 11, 'min std ref order');
    is(MDP->known_std_ref_max_order, 11, 'max std ref order');
    is(MDP->known_std_ref_count, 1, 'std ref count');
    my $itr   = MDP->iterate_known_std_refs;
    $sds      = $itr->();
    ok(defined($sds), 'iterator start');
    is($sds? $sds->order: 0, 11, 'iterator result');
    $sds      = $itr->();
    is($sds, undef, 'iterator end');
    $itr      = MDP->iterate_known_std_refs(16);
    $sds      = $itr->();
    is($sds, undef, 'empty iterator I');
    $itr      = MDP->iterate_known_std_refs(2, 10);
    $sds      = $itr->();
    is($sds, undef, 'empty iterator II');
    $itr      = MDP->iterate_known_std_refs(10, 2);
    $sds      = $itr->();
    is($sds, undef, 'empty iterator III');
    $sds      = MDP->std_reference(16);
    is($sds, undef, 'no test std reference 16');
    $sds      = MDP->lex_reference(16);
    is($sds, undef, 'no test lex reference 16');
    $sds      = eval { MDP->lex_reference(127, 111) };
    is($sds, undef, 'no huge lex reference 16');
    is(MDP->known_lex_ref_min_order, 11, 'lex ref min order');
    is(MDP->known_lex_ref_max_order, 13, 'lex ref max order');
    is(MDP->known_lex_ref_count, 2, 'lex ref count');
    is(MDP->known_gap_ref_min_order, 11, 'gap ref min order');
    is(MDP->known_gap_ref_max_order, 11, 'gap ref max order');
    is(MDP->known_gap_ref_count, 1, 'gap ref count');
    $sds      = MDP->gap_reference(16);
    is($sds, undef, 'no test gap reference 16');
    $db       = File::Spec->catfile($FindBin::Bin, 'db', 'pds_71.db');
    $count    = eval { MDP->set_database($db) };
    ok($count, 'got other test database');
    skip('insufficient test data', 18) if !$count;
    ok(MDP->available(16), 'has test record 16');
    $sds      = MDP->lex_reference(16);
    is($sds, undef, 'has no lex reference');
    $sds      = MDP->gap_reference(16);
    is($sds, undef, 'has no gap reference');
    $ds       = MDP->new(16)->multiply(5);
    ok(defined($ds), 'test set can be multiplied');
    ok(!defined($ds->lambda), 'lambda of test set not known');
    is(MDP->known_std_ref_min_order, undef, 'no std ref min order');
    is(MDP->known_std_ref_max_order, undef, 'no std ref max order');
    is(MDP->known_std_ref_count, 0, 'no std ref count');
    is(MDP->known_lex_ref(2, 4), !1, 'lex ref 2**4 unknown');
    $itr = MDP->iterate_known_lex_refs;
    is($itr->(), undef, 'lex ref list empty');
    is(MDP->known_lex_ref_min_order, undef, 'no lex ref min order');
    is(MDP->known_lex_ref_max_order, undef, 'no lex ref max order');
    is(MDP->known_lex_ref_count, 0, 'no lex ref count');
    is(MDP->known_gap_ref(2, 4), !1, 'gap ref 2**4 unknown');
    $itr = MDP->iterate_known_gap_refs;
    is($itr->(), undef, 'gap ref list empty');
    is(MDP->known_gap_ref_min_order, undef, 'no gap ref min order');
    is(MDP->known_gap_ref_max_order, undef, 'no gap ref max order');
    is(MDP->known_gap_ref_count, 0, 'no gap ref count');
}
