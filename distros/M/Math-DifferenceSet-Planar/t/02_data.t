# Copyright (c) 2019-2024 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# The licence grants freedom for related software development but does
# not cover incorporating code or documentation into AI training material.
# Please contact the copyright holder if you want to use the library whole
# or in part for other purposes than stated in the licence.

# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl 02_data.t'

#########################

use strict;
use warnings;
use File::Spec;
use FindBin;

use Test::More tests => 63;
BEGIN { use_ok('Math::DifferenceSet::Planar::Data') };

#########################

local $Math::DifferenceSet::Planar::Data::DATABASE_DIR =
    File::Spec->catfile($FindBin::Bin, 'db');

my $TYPE_PREFIX = 'Math::DifferenceSet::Planar::Schema::Result::';

my $data = Math::DifferenceSet::Planar::Data->new;
isa_ok($data, 'Math::DifferenceSet::Planar::Data');
is($data->min_order, 2);
is($data->max_order, 257);
is($data->count, 71);
is($data->sp_count, 0);
is($data->sp_min_order, undef);
is($data->sp_max_order, undef);
ok(!$data->iterate_spaces->());
ok(!$data->get_space(8));

my @dbs = Math::DifferenceSet::Planar::Data->list_databases;
is("@dbs", 'pds_71.db pds.db extra.db');

my $extra_path = File::Spec->catfile($FindBin::Bin, 'db', 'extra.db');
$data = Math::DifferenceSet::Planar::Data->new($extra_path);
isa_ok($data, 'Math::DifferenceSet::Planar::Data');
is($data->min_order, 11);
is($data->max_order, 13);
is($data->count, 2);
is($data->path, $extra_path);

$data = Math::DifferenceSet::Planar::Data->new('pds.db');
isa_ok($data, 'Math::DifferenceSet::Planar::Data');
is($data->min_order, 2);
is($data->max_order, 9);
is($data->count, 7);

my $rec = $data->get(9);
isa_ok($rec, $TYPE_PREFIX . 'DifferenceSet');
is($rec->order, 9);
is($rec->base, 3);
SKIP: {
    if ($rec->can('exponent')) {
        is($rec->exponent, 2);
        is($rec->modulus, 91);
        is($rec->n_planes, 12);
    }
    else {
        skip 'reduced database schema', 3;
    }
}
my $ELEMENTS = 'main_elements';
my $DELTAS   = 'delta_main';
if ($rec->can('main_elements')) {
    my @deltas = eval { unpack 'w*', $rec->delta_main };
    like("@deltas", qr/^[0-9]+(?: [0-9]+)\z/);
    is(0+@deltas, 2);
    my $elements = $rec->main_elements;
    is(ref($elements), 'ARRAY');
    is(0+@{$elements}, 2);
}
else {
    $ELEMENTS = 'elements';
    $DELTAS   = 'deltas';
    my @deltas = eval { unpack 'w*', $rec->deltas };
    like("@deltas", qr/^[0-9]+(?: [0-9]+){7}\z/);
    is(0+@deltas, 8);
    my $elements = $rec->elements;
    is(ref($elements), 'ARRAY');
    is(0+@{$elements}, 10);
}

$rec = $data->get(9, qw(base));
isa_ok($rec, 'Math::DifferenceSet::Planar::Schema::Result::DifferenceSet');
ok(!defined $rec->order);
is($rec->base, 3);
ok(!defined $rec->$ELEMENTS);

my $it = $data->iterate(6, 8);
my @ords = ();
my $has_deltas = 1;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas &&= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '7 8');
ok($has_deltas);

$it = $data->iterate_properties;
@ords = ();
$has_deltas = 0;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas ||= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '2 3 4 5 7 8 9');
ok(!$has_deltas);

$it = $data->iterate_properties(4, 7);
@ords = ();
$has_deltas = 0;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas ||= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '4 5 7');
ok(!$has_deltas);

$it = $data->iterate_properties(6);
@ords = ();
$has_deltas = 0;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas ||= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '7 8 9');
ok(!$has_deltas);

$it = $data->iterate_properties(undef, 6);
@ords = ();
$has_deltas = 0;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas ||= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '2 3 4 5');
ok(!$has_deltas);

$it = $data->iterate_properties(8, 6);
@ords = ();
$has_deltas = 0;
while (my $r = $it->()) {
    push @ords, $r->order;
    $has_deltas ||= defined $r->$DELTAS;
    last if @ords >= 10;
}
is("@ords", '8 7');
ok(!$has_deltas);

$it = $data->iterate_properties(undef, undef, qw(order base));
@ords = ();
my @bases = ();
while (my $r = $it->()) {
    push @ords,  $r->order;
    push @bases, $r->base;
    last if @ords >= 10;
}
is("@ords",  '2 3 4 5 7 8 9');
is("@bases", '2 3 2 5 7 2 3');

$it = $data->iterate_properties(4, 5, qw(base));
@bases = ();
my $has_ords = 0;
while (my $r = $it->()) {
    push @bases, $r->base;
    $has_ords ||= defined $r->order;
    last if @bases >= 10;
}
is("@bases", '2 5');
ok(!$has_ords);

my $space = $data->get_space(9);
isa_ok($space, $TYPE_PREFIX . 'DifferenceSetSpace');
is($space->mul_radix, 3);
is($space->mul_depth, 6);
my ($radices, $depths) = $space->rotator_space;
is(ref($radices), 'ARRAY');
is(0+@{$radices}, 1);
is(ref($depths), 'ARRAY');
is("@{$depths}", '12');

$it = $data->iterate_spaces;
@ords = ();
while (my $r = $it->()) {
    push @ords, $r->order;
}
is("@ords", '2 3 4 5 7 8 9');
is($data->sp_count, 7);
is($data->sp_min_order, 2);
is($data->sp_max_order, 9);

my ($major, $minor) = $data->get_version;
diag("main database version is $major.$minor");
ok($major || $minor, 'database version is stored');
($major, $minor) = $data->get_space_version;
diag("space data version is $major.$minor");
ok($major || $minor, 'space data version is stored');
