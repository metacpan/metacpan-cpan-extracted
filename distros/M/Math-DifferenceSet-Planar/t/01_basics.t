# Copyright (c) 2019-2022 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01_basics.t'

#########################

use strict;
use warnings;
use File::Spec;

use Test::More tests => 196;
BEGIN { use_ok('Math::DifferenceSet::Planar') };

#########################

sub pds_ok {
    my ($ds, $res, $com) = @_;
    isa_ok($ds, 'Math::DifferenceSet::Planar');
    SKIP: {
        if (eval { $ds->can('elements') }) {
            my @r = $ds->elements;
            is("@r", $res, $com || ());
        }
        else {
            skip 'no elements from this object', 1;
        }
    }
};

my %p9 = (
    '0 1 3 9 27 49 56 61 77 81'   => '90 0 10 14 30 35 42 64 82 88',
    '0 1 4 13 24 30 38 40 45 73'  => '39 40 58 86 0 2 10 16 27 36',
    '0 1 5 7 27 35 44 67 77 80'   => '76 77 88 0 10 33 42 50 70 72',
    '0 1 5 8 18 20 29 43 59 65'   => '17 18 44 50 66 80 89 0 10 13',
    '0 1 6 10 23 26 34 41 53 55'  => '9 10 46 48 60 67 75 78 0 4',
    '0 1 7 16 27 56 60 68 70 73'  => '69 70 88 0 2 10 14 43 54 63',
    '0 1 11 15 31 36 43 65 83 89' => '10 11 13 19 37 59 66 71 87 0',
    '0 1 12 15 25 48 57 65 85 87' => '24 25 29 31 51 59 68 0 10 13',
    '0 1 19 22 24 32 36 65 76 85' => '31 32 38 47 58 87 0 8 10 13',
    '0 1 19 47 52 54 62 68 79 88' => '61 62 65 74 85 0 8 10 15 43',
    '0 1 27 33 49 63 72 74 84 87' => '83 84 88 0 10 12 21 35 51 57',
    '0 1 37 39 51 58 66 69 82 86' => '0 1 6 10 23 26 34 41 53 55',
);

my %g9 = (
    '0 1 3 9 27 49 56 61 77 81'   => '42 43 45 51 69 0 7 12 28 32',
    '0 1 4 13 24 30 38 40 45 73'  => '46 47 50 59 70 76 84 86 0 28',
    '0 1 5 7 27 35 44 67 77 80'   => '84 85 89 0 20 28 37 60 70 73',
    '0 1 5 8 18 20 29 43 59 65'   => '48 49 53 56 66 68 77 0 16 22',
    '0 1 6 10 23 26 34 41 53 55'  => '57 58 63 67 80 83 0 7 19 21',
    '0 1 7 16 27 56 60 68 70 73'  => '35 36 42 51 62 0 4 12 14 17',
    '0 1 11 15 31 36 43 65 83 89' => '90 0 10 14 30 35 42 64 82 88',
    '0 1 12 15 25 48 57 65 85 87' => '6 7 18 21 31 54 63 71 0 2',
    '0 1 19 22 24 32 36 65 76 85' => '55 56 74 77 79 87 0 29 40 49',
    '0 1 19 47 52 54 62 68 79 88' => '44 45 63 0 5 7 15 21 32 41',
    '0 1 27 33 49 63 72 74 84 87' => '42 43 69 75 0 14 23 25 35 38',
    '0 1 37 39 51 58 66 69 82 86' => '33 34 70 72 84 0 8 11 24 28',
);

my %z789 = (
    '0 1 3 13 32 36 43 52'        => '6 7 9 19 38 42 49 1',
    '0 1 4 9 20 22 34 51'         => '18 19 22 27 38 40 52 12',
    '0 1 4 12 14 30 37 52'        => '24 25 28 36 38 54 4 19',
    '0 1 5 7 17 35 38 49'         => '38 39 43 45 55 16 19 30',
    '0 1 5 27 34 37 43 45'        => '33 34 38 3 10 13 19 21',
    '0 1 6 15 22 26 45 55'        => '50 51 56 8 15 19 38 48',
    '0 1 6 21 28 44 46 54'        => '32 33 38 53 3 19 21 29',
    '0 1 7 19 23 44 47 49'        => '19 20 26 38 42 6 9 11',
    '0 1 7 24 36 38 49 54'        => '38 39 45 5 17 19 30 35',
    '0 1 9 11 14 35 39 51'        => '37 38 46 48 51 15 19 31',
    '0 1 9 20 23 41 51 53'        => '18 19 27 38 41 2 12 14',
    '0 1 13 15 21 24 31 53'       => '23 24 36 38 44 47 54 19',

    '0 1 3 7 15 31 36 54 63'      => '1 2 4 8 16 32 37 55 64',
    '0 1 5 12 18 21 49 51 59'     => '49 50 54 61 67 70 25 27 35',
    '0 1 7 11 35 48 51 53 65'     => '51 52 58 62 13 26 29 31 43',
    '0 1 9 21 23 26 39 63 67'     => '21 22 30 42 44 47 60 11 15',
    '0 1 11 20 38 43 59 67 71'    => '71 72 9 18 36 41 57 65 69',
    '0 1 12 20 26 30 33 35 57'    => '33 34 45 53 59 63 66 68 17',
    '0 1 15 23 25 53 56 62 69'    => '23 24 38 46 48 3 6 12 19',
    '0 1 17 39 41 44 48 54 62'    => '39 40 56 5 7 10 14 20 28',

    '0 1 3 9 27 49 56 61 77 81'   => '0 1 3 9 27 49 56 61 77 81',
    '0 1 4 13 24 30 38 40 45 73'  => '18 19 22 31 42 48 56 58 63 0',
    '0 1 5 7 27 35 44 67 77 80'   => '24 25 29 31 51 59 68 0 10 13',
    '0 1 5 8 18 20 29 43 59 65'   => '0 1 5 8 18 20 29 43 59 65',
    '0 1 6 10 23 26 34 41 53 55'  => '0 1 6 10 23 26 34 41 53 55',
    '0 1 7 16 27 56 60 68 70 73'  => '35 36 42 51 62 0 4 12 14 17',
    '0 1 11 15 31 36 43 65 83 89' => '26 27 37 41 57 62 69 0 18 24',
    '0 1 12 15 25 48 57 65 85 87' => '43 44 55 58 68 0 9 17 37 39',
    '0 1 19 22 24 32 36 65 76 85' => '26 27 45 48 50 58 62 0 11 20',
    '0 1 19 47 52 54 62 68 79 88' => '44 45 63 0 5 7 15 21 32 41',
    '0 1 27 33 49 63 72 74 84 87' => '64 65 0 6 22 36 45 47 57 60',
    '0 1 37 39 51 58 66 69 82 86' => '54 55 0 2 14 21 29 32 45 49',
);

ok(Math::DifferenceSet::Planar->available(9));
ok(Math::DifferenceSet::Planar->available(3, 2));
ok(!Math::DifferenceSet::Planar->available(6));
ok(!Math::DifferenceSet::Planar->available(4, 1));
ok(!Math::DifferenceSet::Planar->available(0, 2));
ok(!Math::DifferenceSet::Planar->available(2, 30));
ok(!Math::DifferenceSet::Planar->available(3, -1));
ok(!Math::DifferenceSet::Planar->available(2, 40));

ok(Math::DifferenceSet::Planar->known_space(9));
ok(!Math::DifferenceSet::Planar->known_space(6));
ok(!Math::DifferenceSet::Planar->known_space(-1));
ok(!Math::DifferenceSet::Planar->known_space(~0>>1&~1));

my $ds = Math::DifferenceSet::Planar->new(9);
my @el = $ds->elements;
ok(exists $p9{"@el"});
pds_ok($ds, "@el");

$ds = Math::DifferenceSet::Planar->new(3, 2);
pds_ok($ds, "@el");

my $ne = $ds->elements;
is($ne, 10);
$ne = $ds->elements_sorted;
is($ne, 10);

is($ds->order, 9);
is($ds->order_base, 3);
is($ds->order_exponent, 2);
is($ds->modulus, 91);
is($ds->element(0), 0);
is($ds->element(9), $el[9]);
is($ds->element(10), undef);

my $ds1 = $ds->translate(10);
my @el1 = map { ($_ + 10) % 91 } @el;
pds_ok($ds1, "@el1");
is($ds1->start_element, 10);
$ds1 = $ds1->translate(-91);
pds_ok($ds1, "@el1");
$ds1 = $ds1->translate(910);
pds_ok($ds1, "@el1");

my $ds1a = $ds->translate(-1);
my @el1a = map { ($_ - 1) % 91 } @el;
pds_ok($ds1a, "@el1a");

my @se = $ds->elements_sorted;
is("@se", "@el");
my @el1s = sort { $a <=> $b } @el1;
@se = $ds1->elements_sorted;
is("@se", "@el1s");

my $ds2 = $ds1->canonize;
pds_ok($ds2, "@el");
$ds2 = $ds->canonize;
pds_ok($ds2, "@el");

my $dsg = $ds->gap_canonize;
pds_ok($dsg, $g9{"@el"});

foreach my $q (7, 8, 9) {
    my $ds = Math::DifferenceSet::Planar->new($q);
    my @el = $ds->elements;
    my $dz = $ds->zeta_canonize;
    pds_ok($dz, $z789{"@el"}, "zeta/$q");
    my $dzz = $dz->zeta_canonize;
    pds_ok($dzz, $z789{"@el"}, "+zeta/$q");
    if (1 == $q % 3) {
        my $dzt = $dz->translate(19)->zeta_canonize;
        pds_ok($dzt, $z789{"@el"}, "zeta+/$q");
    }
}

foreach my $d (71, 0, 45) {
    my @e = $ds->find_delta($d);
    ok(2 == @e);
    ok(2 == grep { 0 <= $_ && $_ < 91 } @e);
    my $delta = $e[1] - $e[0];
    ok($delta == $d || $delta == $d - 91);
}

my $nods = Math::DifferenceSet::Planar->from_elements_fast(
    0, 1, 5, 7, 17, 28, 31, 49
);
my @noe = eval { $nods->find_delta(19) };
ok(0 == @noe);
like($@, qr/^bogus set: delta not found: 19 \(mod 57\)/);

my @pe = $ds->peak_elements;
my $dmax = ($ds->modulus - 1) / 2;
ok(@pe == 2);
ok(($pe[1] - $pe[0]) % $ds->modulus == $dmax);
ok($ds->contains($pe[0]));
ok($ds->contains($pe[1]));
my @pe2 = $ds->peak_elements;
is("@pe2", "@pe");
my @set = grep { $ds->contains($_) } -1 .. 91;
is("@set", "@el");
my @set1 = grep { $ds1->contains($_) } -1 .. 91;
is("@set1", "@el1s");

my $eta = $ds->eta;
ok(0 <= $eta && $eta < 91);
my @mp  = $ds->multiply(3)->elements;
my @te  = $ds->translate($eta)->elements;
is("@mp", "@te");
my $eta2 = $ds->eta;
ok($eta == $eta2);
my $eta3 = Math::DifferenceSet::Planar->from_elements(
    4, 7, 8, 13, 28, 35, 51, 53
)->eta;
is($eta3, 21);

my $zeta = $ds->zeta;
ok(0 <= $zeta && $zeta < 91);
my @mp2  = $ds->multiply(9)->elements;
my @te2  = $ds->translate($zeta)->elements;
is("@mp2", "@te2");
my $ds_zz = Math::DifferenceSet::Planar->from_elements(1, 5, 11, 24, 25, 27);
my $zeta2 = $ds_zz->zeta;
is($zeta2, 0);

my @lg = $ds->largest_gap;
is(0+@lg, 3);
is("@lg", '27 49 22');

SequentialIteratorTest: {
    local $Math::DifferenceSet::Planar::_MAX_ENUM_COUNT = 0;
    local $Math::DifferenceSet::Planar::_USE_SPACES_DB  = 0;
    my $it = $ds->iterate_rotators;
    is(ref($it), 'CODE');
    my @p = ();
    while (my $ro = $it->()) {
      push @p, $ro;
    }
    is("@p", '1 2 4 5 8 10 16 19 20 23 29 46');
    $it = Math::DifferenceSet::Planar->new(8)->iterate_rotators;
    @p = ();
    while (my $ro = $it->()) {
      push @p, $ro;
    }
    is("@p", '1 3 5 9 11 13 17 25');
}

UnstructuredIteratorTest: {
    local $Math::DifferenceSet::Planar::_USE_SPACES_DB  = 0;
    is($ds->n_planes, 12);
    my $it = $ds->iterate_rotators;
    my $it2 = $ds->iterate_rotators;
    is(ref($it), 'CODE');
    my @p = ();
    while (my $ro = $it->()) {
      push @p, $ro;
    }
    is("@p", '1 2 4 5 8 10 16 19 20 23 29 46');
    undef $it;
    is($it2->(), 1);
}

StructuredIteratorTest: {
    $ds = Math::DifferenceSet::Planar->new(9);
    is($ds->n_planes, 12);
    my $it = $ds->iterate_rotators;
    my $it2 = $ds->iterate_rotators;
    is(ref($it), 'CODE');
    my @p = ();
    while (my $ro = $it->()) {
      push @p, $ro;
    }
    like("@p", qr/^1 2 4 8 16 32 [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+ [0-9]+\z/);
    undef $it;
    is($it2->(), 1);
}

my $it3 = $ds->iterate_planes;
pds_ok($it3->(), "@el");
my $nds = $it3->();
my @nel = $nds->elements;
ok("@nel" ne "@el");
ok(exists $p9{"@nel"});
pds_ok($nds, "@nel");
my $c = 2;
while ($it3->() && $c < 99) {
    ++$c;
}
is($c, 12);

my @m = $ds->multipliers;
is("@m", '1 3 9 27 81 61');

my $mul = $ds->multipliers;
is($mul, 6);

my $ds3 = $ds->multiply(1);
pds_ok($ds3, "@el");
my $ds4 = $ds->multiply(10);
my $tel = $p9{"@el"};
pds_ok($ds4, $tel);
$ds3 = $ds->multiply(3)->canonize;
pds_ok($ds3, "@el");
$ds3 = $ds4->multiply(82);
pds_ok($ds3, "@el");

$ds3 = eval { $ds->multiply(35) };
is($ds3, undef);
like($@, qr/^35: factor is not coprime to modulus/);

$ds3 = eval { Math::DifferenceSet::Planar->new(6) };
is($ds3, undef);
like($@, qr/^PDS\(6\) not available/);

$ds3 = eval { Math::DifferenceSet::Planar->new(4, 1) };
is($ds3, undef);
like($@, qr/^PDS\(4, 1\) not available/);

$ds3 = eval { Math::DifferenceSet::Planar->new(0, 2) };
is($ds3, undef);
like($@, qr/^PDS\(0, 2\) not available/);

$ds3 = eval { Math::DifferenceSet::Planar->new(73, 5) };
is($ds3, undef);
like($@, qr/^PDS\(73, 5\) not available/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    1, 2, 4, 10, 28, 50, 57, 62, 78, 82,
)};
pds_ok($ds3, '1 2 4 10 28 50 57 62 78 82');

$ds3 = eval { Math::DifferenceSet::Planar->from_elements($ds3->elements) };
pds_ok($ds3, '1 2 4 10 28 50 57 62 78 82');

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    -9, 2, 4, 10, 28, 50, 57, 62, 78
)};
is($ds3, undef);
like($@, qr/^element values inside range 0\.\.72 expected/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(0) };
is($ds3, undef);
like($@, qr/^this implementation cannot handle order 0/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    1, 2, 4, 8, 16, 32, 21
)};
is($ds3, undef);
like($@, qr/^this implementation cannot handle order 6/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    0, 1, 10
)};
is($ds3, undef);
like($@, qr/^element values inside range 0..6 expected/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    0, 2, 4
)};
is($ds3, undef);
like($@, qr/^delta 1 elements missing/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    0, 1, 1
)};
is($ds3, undef);
like($@, qr/^duplicate element: 1/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    0, 1, 2
)};
is($ds3, undef);
like($@, qr/^apparently not a planar difference set/);

$ds3 = eval { Math::DifferenceSet::Planar->from_elements(
    0, 1, 5, 7, 17, 28, 31, 49
)};
is($ds3, undef);
like($@, qr/^apparently not a planar difference set/);

my $rc = Math::DifferenceSet::Planar->verify_elements(1, 2, 4);
is($rc, 1);
$rc = Math::DifferenceSet::Planar->verify_elements(1, 2, 4, 1);
is($rc, q[]);
$rc = Math::DifferenceSet::Planar->verify_elements(1, 2, 3);
is($rc, q[]);
$rc = Math::DifferenceSet::Planar->verify_elements(-1, 2, 4);
is($rc, undef);
$rc = Math::DifferenceSet::Planar->verify_elements(1, 2.5, 4);
is($rc, undef);
$rc = Math::DifferenceSet::Planar->verify_elements(1, 2, 7);
is($rc, undef);
$rc = Math::DifferenceSet::Planar->verify_elements(0, 1);
is($rc, undef);
$rc = Math::DifferenceSet::Planar->verify_elements(4, 2, 1);
is($rc, 1);

SKIP: {
    if (Math::DifferenceSet::Planar->available(2, 10)) {
        my $ds4 = Math::DifferenceSet::Planar->new(2, 10);
        my $nm  = eval { $ds4->n_planes };
        diag("PDS(2, 10) has $nm planes\n") if defined $nm;
        ok(!defined($nm) || $nm == 19800);
        ok( defined($nm) || $@ =~ /^planes not supported for orders > /);
    }
    else {
        skip 'medium size sets not supported', 2;
    }
};

SKIP: {
    if (Math::DifferenceSet::Planar->available(3, 9)) {
        my $ds4 = Math::DifferenceSet::Planar->new(3, 9);
        my $nm  = eval { $ds4->n_planes };
        diag("PDS(3, 9) has $nm planes\n") if defined $nm;
        ok(!defined($nm) || $nm == 14183424);
        ok( defined($nm) || $@ =~ /^planes not supported for orders > /);
    }
    else {
        skip 'large sets not supported', 2;
    }
};

my $sit = Math::DifferenceSet::Planar->iterate_available_sets(10, 20);
my $isa = 1;
my @ords = ();
while (my $ds = $sit->()) {
    $isa &&= $ds->isa('Math::DifferenceSet::Planar');
    push @ords, $ds->order;
    last if @ords >= 6;
}
ok($isa);
is("@ords", '11 13 16 17 19');

$sit = Math::DifferenceSet::Planar->iterate_available_sets(20, 10);
$isa = 1;
@ords = ();
while (my $ds = $sit->()) {
    $isa &&= $ds->isa('Math::DifferenceSet::Planar');
    push @ords, $ds->order;
    last if @ords >= 6;
}
ok($isa);
is("@ords", '19 17 16 13 11');

$sit = Math::DifferenceSet::Planar->iterate_available_sets(10);
$isa = 1;
@ords = ();
while (my $ds = $sit->()) {
    $isa &&= $ds->isa('Math::DifferenceSet::Planar');
    push @ords, $ds->order;
    last if @ords >= 5;
}
ok($isa);
is("@ords", '11 13 16 17 19');

$sit = Math::DifferenceSet::Planar->iterate_available_sets(undef, 7);
$isa = 1;
@ords = ();
while (my $ds = $sit->()) {
    $isa &&= $ds->isa('Math::DifferenceSet::Planar');
    push @ords, $ds->order;
    last if @ords >= 6;
}
ok($isa);
is("@ords", '2 3 4 5 7');

$sit = Math::DifferenceSet::Planar->iterate_available_sets;
$isa = 1;
@ords = ();
while (my $ds = $sit->()) {
    $isa &&= $ds->isa('Math::DifferenceSet::Planar');
    push @ords, $ds->order;
    last if @ords >= 5;
}
ok($isa);
is("@ords", '2 3 4 5 7');
undef $sit;

my $count = Math::DifferenceSet::Planar->available_count;
diag("number of available sets is $count");
like($count, qr/^[1-9][0-9]*\z/);

my $min = Math::DifferenceSet::Planar->available_min_order;
diag("minimal available order is $min");
is($min, 2);

my $max = Math::DifferenceSet::Planar->available_max_order;
diag("maximal available order is $max");
like($max, qr/^[1-9][0-9]*\z/);

my $spc_count = Math::DifferenceSet::Planar->known_space_count;
diag("number of known spaces is $spc_count");
like($spc_count, qr/^(?:0|[1-9][0-9]*)\z/);

$min = Math::DifferenceSet::Planar->known_space_min_order;
my $qmin = defined($min)? $min: 'undefined';
diag("minimal known space order is $qmin");
if($spc_count) {
    like($min, qr/^[1-9][0-9]*\z/);
}
else {
    ok(!defined $min);
}

$max = Math::DifferenceSet::Planar->known_space_max_order;
diag("maximal known space order is $max");
like($max, qr/^(?:0|[1-9][0-9]*)\z/);

my $desc = Math::DifferenceSet::Planar->known_space_desc(9);
is($desc, '9: 3^6 [2^12]');
$desc = Math::DifferenceSet::Planar->known_space_desc(0);
ok(!defined $desc);
$desc = Math::DifferenceSet::Planar->known_space_desc(1);
ok(!defined $desc);
$desc = Math::DifferenceSet::Planar->known_space_desc(2147483646);
ok(!defined $desc);

my $spit = Math::DifferenceSet::Planar->iterate_known_spaces(10, 20);
my @spcs = ();
my $P_RE = qr/[0-9]+\^[0-9]+/;
while (my $desc = $spit->()) {
    if ($desc =~ /^([0-9]+): ($P_RE) \[$P_RE(?: $P_RE)*\]\z/) {
        push @spcs, "$1/$2";
    }
    else {
        push @spcs, '?';
    }
    last if @spcs >= 6;
}
is(0+@spcs, 5);
is("@spcs", '11/11^3 13/13^3 16/2^12 17/17^3 19/19^3');

$spit = Math::DifferenceSet::Planar->iterate_known_spaces(20, 10);
@spcs = ();
while (my $desc = $spit->()) {
    if ($desc =~ /^([0-9]+): ($P_RE) \[$P_RE(?: $P_RE)*\]\z/) {
        push @spcs, "$1/$2";
    }
    else {
        push @spcs, '?';
    }
    last if @spcs >= 6;
}
is(0+@spcs, 5);
is("@spcs", '19/19^3 17/17^3 16/2^12 13/13^3 11/11^3');

$spit = Math::DifferenceSet::Planar->iterate_known_spaces(10);
@spcs = ();
while (my $desc = $spit->()) {
    if ($desc =~ /^([0-9]+): ($P_RE) \[$P_RE(?: $P_RE)*\]\z/) {
        push @spcs, "$1/$2";
    }
    else {
        push @spcs, '?';
    }
    last if @spcs >= 5;
}
is(0+@spcs, 5);
is("@spcs", '11/11^3 13/13^3 16/2^12 17/17^3 19/19^3');

$spit = Math::DifferenceSet::Planar->iterate_known_spaces(undef, 7);
@spcs = ();
while (my $desc = $spit->()) {
    if ($desc =~ /^([0-9]+): ($P_RE) \[$P_RE(?: $P_RE)*\]\z/) {
        push @spcs, "$1/$2";
    }
    else {
        push @spcs, '?';
    }
    last if @spcs >= 6;
}
is(0+@spcs, 5);
is("@spcs", '2/2^3 3/3^3 4/2^6 5/5^3 7/7^3');

undef $spit;

my @db = Math::DifferenceSet::Planar->list_databases;
diag("available databases: @db");
ok(1 <= grep { 'pds.db' eq lc $_ } @db);

my $ds_b = Math::DifferenceSet::Planar->new(8)->translate(-1)->multiply(44);

my $c2 = eval { Math::DifferenceSet::Planar->set_database($db[0]) };
is($c2, $count);

my $ds_a = Math::DifferenceSet::Planar->new(8);
my @maps = $ds_b->find_all_linear_maps($ds_a);
is(0+@maps, 9);
my $md = join q[ ], map {join q[|], @{$_}} @maps;
is($md, '5|1 7|31 10|3 14|63 20|7 28|54 39|0 40|15 56|36');

my $ds_c = Math::DifferenceSet::Planar->from_elements_fast($ds_b->elements);
my ($f, $d) = $ds_c->find_linear_map($ds_a);
my $found = grep { $_->[0] == $f && $_->[1] == $d } @maps;
is($found, 1);
$ds_c = Math::DifferenceSet::Planar->from_elements_fast($ds_b->elements);
my $ds_d = $ds_c->multiply(2)->translate(-$ds_c->zeta);;
($f, $d) = $ds_c->find_linear_map($ds_c);
is("$f|$d", '1|0');
ok($ds_c->same_plane($ds_d));

$c2 = eval { Math::DifferenceSet::Planar->set_database('NONEXISTENT.FILE') };
is($c2, undef);
like($@, qr/^bad database: file does not exist:/);

my $tmpdb = File::Spec->catfile(File::Spec->rel2abs("t"), 'tmp.db');
SKIP: {
    if (open my $fh, '>', $tmpdb) {
        close $fh;
        $c2 = eval { Math::DifferenceSet::Planar->set_database($tmpdb) };
        is($c2, undef);
        like($@, qr/^bad database: query failed:/);
        unlink $tmpdb;
    }
    else {
        skip 'temporary file not writable', 2;
    }
}

MEMO_TEST: {
    local $Math::DifferenceSet::Planar::_MAX_MEMO_COUNT = 1;
    my $ds = Math::DifferenceSet::Planar->from_elements(
        0, 1, 3, 7, 15, 31, 36, 54, 63
    );
    pds_ok($ds, '0 1 3 7 15 31 36 54 63');
}
