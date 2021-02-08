# Copyright (c) 2019-2021 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 01_basics.t'

#########################

use strict;
use warnings;
use File::Spec;

use Test::More tests => 137;
BEGIN { use_ok('Math::DifferenceSet::Planar') };

#########################

sub pds_ok {
    my ($ds, $res) = @_;
    isa_ok($ds, 'Math::DifferenceSet::Planar');
    SKIP: {
        if (eval { $ds->can('elements') }) {
            my @r = $ds->elements;
            is("@r", $res);
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

ok(Math::DifferenceSet::Planar->available(9));
ok(Math::DifferenceSet::Planar->available(3, 2));
ok(!Math::DifferenceSet::Planar->available(6));
ok(!Math::DifferenceSet::Planar->available(4, 1));
ok(!Math::DifferenceSet::Planar->available(0, 2));
ok(!Math::DifferenceSet::Planar->available(2, 30));
ok(!Math::DifferenceSet::Planar->available(3, -1));
ok(!Math::DifferenceSet::Planar->available(2, 40));

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

my @e;
foreach my $d (71, 0, 45) {
    @e = $ds->find_delta($d);
    ok(2 == @e);
    ok(2 == grep { 0 <= $_ && $_ < 91 } @e);
    my $delta = $e[1] - $e[0];
    ok($delta == $d || $delta == $d - 91);
}

my $nods = Math::DifferenceSet::Planar->from_elements(
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

SequentialIteratorTest: {
    local $Math::DifferenceSet::Planar::_MAX_ENUM_COUNT = 0;
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

my $max = Math::DifferenceSet::Planar->available_max_order;
diag("maximal available order is $max");
like($max, qr/^[1-9][0-9]*\z/);

my @db = Math::DifferenceSet::Planar->list_databases;
diag("available databases: @db");
ok(1 <= grep { 'pds.db' eq lc $_ } @db);

my $c2 = eval { Math::DifferenceSet::Planar->set_database($db[0]) };
is($c2, $count);

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
