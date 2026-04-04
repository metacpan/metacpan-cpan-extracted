#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# ============================================================
# Legba::add
# ============================================================

subtest 'add creates slot without accessor' => sub {
    Legba::add('add_only');
    ok(Legba::exists('add_only'),         'slot exists after add');
    ok(!main->can('add_only'),            'no accessor installed in main');
    ok(!defined Legba::get('add_only'),   'value starts undef');
};

subtest 'add is idempotent' => sub {
    Legba::add('add_idem');
    Legba::set('add_idem', 'original');
    Legba::add('add_idem');   # second add should be a no-op
    is(Legba::get('add_idem'), 'original', 'value unchanged after second add');
    ok(Legba::exists('add_idem'), 'slot still exists');
};

subtest 'add multiple at once' => sub {
    Legba::add('add_m1', 'add_m2', 'add_m3');
    ok(Legba::exists('add_m1'), 'add_m1 exists');
    ok(Legba::exists('add_m2'), 'add_m2 exists');
    ok(Legba::exists('add_m3'), 'add_m3 exists');
};

# ============================================================
# Legba::get / Legba::set
# ============================================================

subtest 'get and set by name' => sub {
    Legba::add('gs_test');
    Legba::set('gs_test', 'hello');
    is(Legba::get('gs_test'), 'hello', 'get returns set value');

    Legba::set('gs_test', [1, 2, 3]);
    is_deeply(Legba::get('gs_test'), [1, 2, 3], 'get/set round-trips arrayref');
};

subtest 'set creates slot if missing' => sub {
    ok(!Legba::exists('set_creates'), 'slot absent before set');
    Legba::set('set_creates', 'auto');
    ok(Legba::exists('set_creates'), 'slot created by set');
    is(Legba::get('set_creates'), 'auto', 'value correct');
};

subtest 'get returns undef for unknown slot' => sub {
    ok(!Legba::exists('get_unknown_xyz'), 'slot does not exist');
    my $v = Legba::get('get_unknown_xyz');
    ok(!defined $v, 'get returns undef for unknown slot');
};

subtest 'set returns the stored value' => sub {
    Legba::add('set_ret');
    my $r = Legba::set('set_ret', 99);
    is($r, 99, 'set returns the value');
};

subtest 'set respects lock' => sub {
    Legba::add('set_locked');
    Legba::set('set_locked', 'before');
    Legba::_lock('set_locked');
    eval { Legba::set('set_locked', 'after') };
    like($@, qr/locked/, 'set croaks on locked slot');
    is(Legba::get('set_locked'), 'before', 'value unchanged');
    Legba::_unlock('set_locked');
};

subtest 'set respects freeze' => sub {
    Legba::add('set_frozen');
    Legba::set('set_frozen', 'before');
    Legba::_freeze('set_frozen');
    eval { Legba::set('set_frozen', 'after') };
    like($@, qr/frozen/, 'set croaks on frozen slot');
    is(Legba::get('set_frozen'), 'before', 'value unchanged');
};

# ============================================================
# Legba::index
# ============================================================

subtest 'index returns numeric index' => sub {
    Legba::add('idx_test');
    my $i = Legba::index('idx_test');
    ok(defined $i,    'index returns defined value');
    ok($i >= 0,       'index is non-negative');
};

subtest 'index is stable' => sub {
    Legba::add('idx_stable');
    my $i1 = Legba::index('idx_stable');
    Legba::set('idx_stable', 'something');
    my $i2 = Legba::index('idx_stable');
    is($i1, $i2, 'index unchanged after value change');
};

subtest 'index returns undef for unknown slot' => sub {
    my $i = Legba::index('idx_never_created_xyz');
    ok(!defined $i, 'index undef for unknown slot');
};

subtest 'different slots get different indices' => sub {
    Legba::add('idx_diff_a', 'idx_diff_b');
    my $a = Legba::index('idx_diff_a');
    my $b = Legba::index('idx_diff_b');
    isnt($a, $b, 'different slots have different indices');
};

# ============================================================
# Legba::get_by_idx / Legba::set_by_idx
# ============================================================

subtest 'get_by_idx returns value' => sub {
    Legba::add('gbi_test');
    Legba::set('gbi_test', 'indexed_val');
    my $idx = Legba::index('gbi_test');
    is(Legba::get_by_idx($idx), 'indexed_val', 'get_by_idx returns correct value');
};

subtest 'set_by_idx stores value' => sub {
    Legba::add('sbi_test');
    my $idx = Legba::index('sbi_test');
    Legba::set_by_idx($idx, 'via_idx');
    is(Legba::get('sbi_test'),     'via_idx', 'get sees value from set_by_idx');
    is(Legba::get_by_idx($idx),    'via_idx', 'get_by_idx sees own write');
};

subtest 'set_by_idx returns value' => sub {
    Legba::add('sbi_ret');
    my $idx = Legba::index('sbi_ret');
    my $r = Legba::set_by_idx($idx, 42);
    is($r, 42, 'set_by_idx returns stored value');
};

subtest 'set_by_idx visible via accessor' => sub {
    package SbiPkg;
    use Legba qw/sbi_pkg_slot/;
    package main;
    my $idx = Legba::index('sbi_pkg_slot');
    Legba::set_by_idx($idx, 'from_idx');
    is(SbiPkg::sbi_pkg_slot(), 'from_idx', 'accessor sees set_by_idx value');
};

subtest 'set_by_idx respects lock' => sub {
    Legba::add('sbi_lock');
    my $idx = Legba::index('sbi_lock');
    Legba::set_by_idx($idx, 'safe');
    Legba::_lock('sbi_lock');
    eval { Legba::set_by_idx($idx, 'blocked') };
    like($@, qr/locked/, 'set_by_idx croaks on locked slot');
    is(Legba::get_by_idx($idx), 'safe', 'value unchanged');
    Legba::_unlock('sbi_lock');
};

subtest 'set_by_idx respects freeze' => sub {
    Legba::add('sbi_freeze');
    my $idx = Legba::index('sbi_freeze');
    Legba::set_by_idx($idx, 'safe');
    Legba::_freeze('sbi_freeze');
    eval { Legba::set_by_idx($idx, 'blocked') };
    like($@, qr/frozen/, 'set_by_idx croaks on frozen slot');
};

subtest 'get_by_idx out of range returns undef' => sub {
    my $v = Legba::get_by_idx(999999);
    ok(!defined $v, 'get_by_idx out of range returns undef');
};

# ============================================================
# Legba::slots
# ============================================================

subtest 'slots returns all slot names' => sub {
    Legba::add('slots_a', 'slots_b', 'slots_c');
    my %all = map { $_ => 1 } Legba::slots();
    ok($all{slots_a}, 'slots_a in slots()');
    ok($all{slots_b}, 'slots_b in slots()');
    ok($all{slots_c}, 'slots_c in slots()');
};

subtest 'slots and _keys return same names' => sub {
    my %via_slots = map { $_ => 1 } Legba::slots();
    my %via_keys  = map { $_ => 1 } Legba::_keys();
    is_deeply(\%via_slots, \%via_keys, 'slots() and _keys() agree');
};

# ============================================================
# Legba::exists
# ============================================================

subtest 'exists returns true for known slot' => sub {
    Legba::add('ex_known');
    ok(Legba::exists('ex_known'), 'exists true for known slot');
};

subtest 'exists returns false for unknown slot' => sub {
    ok(!Legba::exists('ex_never_xyz'), 'exists false for unknown slot');
};

subtest 'exists true even with undef value' => sub {
    Legba::add('ex_undef');
    ok(!defined Legba::get('ex_undef'), 'value is undef');
    ok(Legba::exists('ex_undef'),       'slot still exists');
};

subtest 'exists and _exists agree' => sub {
    Legba::add('ex_agree');
    is(Legba::exists('ex_agree'),  Legba::_exists('ex_agree'),  'agree on existing');
    is(Legba::exists('ex_no_xyz'), Legba::_exists('ex_no_xyz'), 'agree on missing');
};

# ============================================================
# Legba::clear (named)
# ============================================================

subtest 'clear resets value to undef' => sub {
    Legba::add('clr_val');
    Legba::set('clr_val', 'data');
    Legba::clear('clr_val');
    ok(!defined Legba::get('clr_val'), 'value undef after clear');
    ok(Legba::exists('clr_val'),       'slot still exists after clear');
};

subtest 'clear multiple names' => sub {
    Legba::add('clr_m1', 'clr_m2', 'clr_m3');
    Legba::set('clr_m1', 1); Legba::set('clr_m2', 2); Legba::set('clr_m3', 3);
    Legba::clear('clr_m1', 'clr_m2');
    ok(!defined Legba::get('clr_m1'), 'clr_m1 cleared');
    ok(!defined Legba::get('clr_m2'), 'clr_m2 cleared');
    is(Legba::get('clr_m3'), 3,       'clr_m3 untouched');
};

subtest 'clear skips locked slot' => sub {
    Legba::add('clr_lock');
    Legba::set('clr_lock', 'protected');
    Legba::_lock('clr_lock');
    Legba::clear('clr_lock');
    is(Legba::get('clr_lock'), 'protected', 'locked slot survives clear');
    Legba::_unlock('clr_lock');
};

subtest 'clear skips frozen slot' => sub {
    Legba::add('clr_frozen2');
    Legba::set('clr_frozen2', 'immutable');
    Legba::_freeze('clr_frozen2');
    Legba::clear('clr_frozen2');
    is(Legba::get('clr_frozen2'), 'immutable', 'frozen slot survives clear');
};

# ============================================================
# Legba::clear_by_idx
# ============================================================

subtest 'clear_by_idx resets value' => sub {
    Legba::add('clri_test');
    Legba::set('clri_test', 'has_value');
    my $idx = Legba::index('clri_test');
    Legba::clear_by_idx($idx);
    ok(!defined Legba::get('clri_test'), 'value undef after clear_by_idx');
    ok(Legba::exists('clri_test'),       'slot still exists');
};

subtest 'clear_by_idx multiple indices' => sub {
    Legba::add('clri_a', 'clri_b');
    Legba::set('clri_a', 'aa'); Legba::set('clri_b', 'bb');
    Legba::clear_by_idx(Legba::index('clri_a'), Legba::index('clri_b'));
    ok(!defined Legba::get('clri_a'), 'clri_a cleared by idx');
    ok(!defined Legba::get('clri_b'), 'clri_b cleared by idx');
};

# ============================================================
# import idempotency
# ============================================================

subtest 'import is idempotent' => sub {
    package IdemPkg;
    use Legba qw/idem_slot/;
    IdemPkg::idem_slot('first');
    use Legba qw/idem_slot/;   # second import of same slot
    package main;
    is(IdemPkg::idem_slot(), 'first', 'value unchanged after re-import');
    ok(IdemPkg->can('idem_slot'), 'accessor still exists');
};

# ============================================================
# get/set vs _get/_set aliasing
# ============================================================

subtest 'get/_get and set/_set are interchangeable' => sub {
    Legba::add('alias_test');
    Legba::set('alias_test', 'via set');
    is(Legba::_get('alias_test'), 'via set', '_get sees value from set');
    Legba::_set('alias_test', 'via _set');
    is(Legba::get('alias_test'), 'via _set', 'get sees value from _set');
};

done_testing();
