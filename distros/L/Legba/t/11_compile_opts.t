#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# This file tests compile-time optimization paths:
#   - get('constant')   => pp_slot_get custom op
#   - set('constant', val) => pp_slot_set custom op
#   - index('constant') => OP_CONST (constant fold)
#   - watch('constant', cb) => pp_slot_watch custom op
#   - unwatch('constant')   => pp_slot_unwatch custom op
#   - clear('constant')     => pp_slot_clear custom op
#
# For optimization to fire, the slot must exist at compile time
# (created via 'use Legba qw/name/'). We verify correctness of the
# optimized path — the custom op is transparent to the caller.

# ============================================================
# Slots created at compile time for optimizer tests
# ============================================================

use Legba qw/
    opt_get_slot
    opt_set_slot
    opt_idx_slot
    opt_watch_slot
    opt_unwatch_slot
    opt_clear_slot
    opt_rw_slot
/;

# ============================================================
# get('constant') optimization
# ============================================================

subtest 'get constant optimized - returns correct value' => sub {
    opt_get_slot('expected');
    my $v = Legba::get('opt_get_slot');
    is($v, 'expected', 'get constant returns value set via accessor');

    Legba::set('opt_get_slot', 'updated');
    is(Legba::get('opt_get_slot'), 'updated', 'get constant sees updated value');
};

subtest 'get constant agrees with _get' => sub {
    opt_get_slot('agree_val');
    is(Legba::get('opt_get_slot'), Legba::_get('opt_get_slot'),
       'get and _get return same value');
};

subtest 'get constant with undef' => sub {
    opt_get_slot(undef);
    ok(!defined Legba::get('opt_get_slot'), 'get constant handles undef');
};

subtest 'get constant with reference' => sub {
    my $href = { key => 'val' };
    opt_get_slot($href);
    is_deeply(Legba::get('opt_get_slot'), $href, 'get constant returns ref intact');
};

# ============================================================
# set('constant', val) optimization
# ============================================================

subtest 'set constant stores value' => sub {
    Legba::set('opt_set_slot', 'stored');
    is(opt_set_slot(), 'stored', 'accessor sees value from set constant');
};

subtest 'set constant returns value' => sub {
    my $r = Legba::set('opt_set_slot', 42);
    is($r, 42, 'set constant returns stored value');
};

subtest 'set constant with arrayref' => sub {
    Legba::set('opt_set_slot', [10, 20, 30]);
    is_deeply(opt_set_slot(), [10, 20, 30], 'set constant stores arrayref');
};

subtest 'set constant overwrites previous' => sub {
    Legba::set('opt_set_slot', 'first');
    Legba::set('opt_set_slot', 'second');
    is(opt_set_slot(), 'second', 'second set constant wins');
};

subtest 'set constant respects lock' => sub {
    opt_rw_slot('before');
    Legba::_lock('opt_rw_slot');
    eval { Legba::set('opt_rw_slot', 'after') };
    like($@, qr/locked/, 'set constant croaks on locked slot');
    is(opt_rw_slot(), 'before', 'value unchanged');
    Legba::_unlock('opt_rw_slot');
};

subtest 'set constant respects freeze' => sub {
    opt_rw_slot('safe');
    Legba::_freeze('opt_rw_slot');
    eval { Legba::set('opt_rw_slot', 'blocked') };
    like($@, qr/frozen/, 'set constant croaks on frozen slot');
    is(opt_rw_slot(), 'safe', 'value unchanged');
};

# ============================================================
# index('constant') constant folding
# ============================================================

subtest 'index constant returns numeric index' => sub {
    my $i = Legba::index('opt_idx_slot');
    ok(defined $i, 'index constant returns defined');
    ok($i >= 0,    'index constant is non-negative');
};

subtest 'index constant is stable' => sub {
    my $i1 = Legba::index('opt_idx_slot');
    opt_idx_slot('changed');
    my $i2 = Legba::index('opt_idx_slot');
    is($i1, $i2, 'index constant stable after value change');
};

subtest 'index constant matches index by variable' => sub {
    my $name = 'opt_idx_slot';
    my $i_const = Legba::index('opt_idx_slot');
    my $i_var   = Legba::index($name);
    is($i_const, $i_var, 'constant-folded index matches runtime index');
};

subtest 'index constant usable with get_by_idx' => sub {
    opt_idx_slot('idx_val');
    my $idx = Legba::index('opt_idx_slot');
    is(Legba::get_by_idx($idx), 'idx_val', 'get_by_idx via constant index works');
};

# ============================================================
# Accessor call checker (0-arg getter, 1-arg setter)
# ============================================================

subtest 'accessor 0-arg getter optimized' => sub {
    opt_get_slot('getter_test');
    my $v = opt_get_slot();
    is($v, 'getter_test', 'accessor getter returns value');
};

subtest 'accessor 1-arg setter optimized' => sub {
    opt_set_slot('setter_test');
    is(Legba::get('opt_set_slot'), 'setter_test', 'accessor setter stores value');
};

subtest 'accessor getter/setter round-trip' => sub {
    for my $val ('string', 42, 3.14, undef, [1,2,3], {a=>1}) {
        opt_rw_slot($val) if !Legba::_is_frozen('opt_rw_slot');
        # opt_rw_slot may be frozen from previous subtest; use get_slot instead
        opt_get_slot($val);
        my $got = opt_get_slot();
        if (defined $val && ref $val) {
            is_deeply($got, $val, "round-trip: ref");
        } elsif (defined $val) {
            is($got, $val, "round-trip: $val");
        } else {
            ok(!defined $got, 'round-trip: undef');
        }
    }
};

# ============================================================
# watch('constant', cb) optimization
# ============================================================

subtest 'watch constant fires on set' => sub {
    my @calls;
    Legba::watch('opt_watch_slot', sub { push @calls, [@_] });
    Legba::set('opt_watch_slot', 'watched');
    is(scalar @calls, 1,              'watcher fired via watch constant');
    is($calls[0][0], 'opt_watch_slot','name arg correct');
    is($calls[0][1], 'watched',       'value arg correct');
    Legba::unwatch('opt_watch_slot');
};

subtest 'watch constant fires on accessor set' => sub {
    my $count = 0;
    Legba::watch('opt_watch_slot', sub { $count++ });
    opt_watch_slot('via_accessor');
    is($count, 1, 'watch constant watcher fires via accessor');
    Legba::unwatch('opt_watch_slot');
};

# ============================================================
# unwatch('constant') optimization
# ============================================================

subtest 'unwatch constant removes all watchers' => sub {
    my $count = 0;
    Legba::watch('opt_unwatch_slot', sub { $count++ });
    Legba::watch('opt_unwatch_slot', sub { $count++ });
    opt_unwatch_slot('before');
    is($count, 2, 'both watchers fire before unwatch');

    Legba::unwatch('opt_unwatch_slot');
    opt_unwatch_slot('after');
    is($count, 2, 'no watchers fire after unwatch constant');
};

# ============================================================
# clear('constant') optimization
# ============================================================

subtest 'clear constant resets value' => sub {
    opt_clear_slot('has_data');
    is(Legba::get('opt_clear_slot'), 'has_data', 'value set');
    Legba::clear('opt_clear_slot');
    ok(!defined Legba::get('opt_clear_slot'), 'value undef after clear constant');
};

subtest 'clear constant removes watchers' => sub {
    my $count = 0;
    Legba::watch('opt_clear_slot', sub { $count++ });
    Legba::set('opt_clear_slot', 'x');
    is($count, 1, 'watcher fired before clear');
    Legba::clear('opt_clear_slot');
    Legba::set('opt_clear_slot', 'y');
    is($count, 1, 'watcher gone after clear constant');
};

subtest 'clear constant slot still exists' => sub {
    Legba::clear('opt_clear_slot');
    ok(Legba::exists('opt_clear_slot'), 'slot exists after clear');
};

# ============================================================
# Verify constant-optimized paths and dynamic paths agree
# ============================================================

subtest 'constant and dynamic paths agree on reads' => sub {
    my $name = 'opt_get_slot';
    opt_get_slot('consistency');
    is(Legba::get('opt_get_slot'), Legba::get($name),
       'constant get and dynamic get agree');
};

subtest 'constant and dynamic paths agree on writes' => sub {
    my $name = 'opt_set_slot';
    Legba::set('opt_set_slot', 'const_write');
    is(opt_set_slot(),          'const_write', 'accessor sees const write');
    is(Legba::get($name),       'const_write', 'dynamic get sees const write');
    Legba::set($name, 'dyn_write');
    is(Legba::get('opt_set_slot'), 'dyn_write', 'const get sees dyn write');
};

done_testing();
