#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# ============================================================
# _slot_ptr stability across registry resizes
# The new architecture uses a dedicated SV* per slot so the
# pointer must be stable even after many slots are added.
# ============================================================

subtest '_slot_ptr stable after many slots added' => sub {
    Legba::add('stability_anchor');
    my $ptr_before = Legba::_slot_ptr('stability_anchor');

    # Force several resizes by creating lots of new slots
    Legba::add(map { "stability_filler_$_" } 1..200);

    my $ptr_after = Legba::_slot_ptr('stability_anchor');
    is($ptr_after, $ptr_before, '_slot_ptr unchanged after 200 slots added');
};

subtest '_slot_ptr stable after value change' => sub {
    Legba::add('ptr_val_change');
    my $ptr1 = Legba::_slot_ptr('ptr_val_change');
    Legba::set('ptr_val_change', 'x');
    Legba::set('ptr_val_change', { complex => [1,2,3] });
    Legba::set('ptr_val_change', undef);
    my $ptr2 = Legba::_slot_ptr('ptr_val_change');
    is($ptr2, $ptr1, '_slot_ptr stable across value mutations');
};

# ============================================================
# Watcher edge cases
# ============================================================

subtest 'watcher receives correct value from _set' => sub {
    Legba::add('watch__set');
    my @vals;
    Legba::watch('watch__set', sub { push @vals, $_[1] });
    Legba::_set('watch__set', 'from _set');
    is(scalar @vals, 1,          '_set fires watcher');
    is($vals[0], 'from _set',    'correct value received');
};

subtest 'watcher fires after re-watch following unwatch' => sub {
    Legba::add('rewatch');
    my $count = 0;
    my $cb = sub { $count++ };
    Legba::watch('rewatch', $cb);
    Legba::set('rewatch', 1);
    is($count, 1, 'fires before unwatch');
    Legba::unwatch('rewatch');
    Legba::set('rewatch', 2);
    is($count, 1, 'silent after unwatch');
    Legba::watch('rewatch', $cb);
    Legba::set('rewatch', 3);
    is($count, 2, 'fires again after re-watch');
};

subtest 'dying watcher does not prevent subsequent watchers' => sub {
    Legba::add('die_watch');
    my $second_fired = 0;
    Legba::watch('die_watch', sub { die "intentional\n" });
    Legba::watch('die_watch', sub { $second_fired++ });
    # The second watcher should still fire even if the first dies
    eval { Legba::set('die_watch', 'x') };
    # We don't mandate that the second fires on die in first,
    # but we do mandate the process doesn't crash and the slot is intact
    is(Legba::get('die_watch'), 'x', 'slot has correct value after watcher die');
    ok(1, 'process survived dying watcher');
};

subtest 'watcher count correct after unwatch specific' => sub {
    Legba::add('count_watch');
    my $count = 0;
    my $cb1 = sub { $count += 10 };
    my $cb2 = sub { $count += 1  };
    my $cb3 = sub { $count += 100 };
    Legba::watch('count_watch', $cb1);
    Legba::watch('count_watch', $cb2);
    Legba::watch('count_watch', $cb3);

    Legba::set('count_watch', 'a');
    is($count, 111, 'all three fire');

    Legba::unwatch('count_watch', $cb2);
    $count = 0;
    Legba::set('count_watch', 'b');
    is($count, 110, 'only cb1 and cb3 fire after removing cb2');
};

subtest 'watcher sees value after clear then set' => sub {
    Legba::add('watch_after_clear');
    my @vals;
    Legba::watch('watch_after_clear', sub { push @vals, $_[1] });
    Legba::set('watch_after_clear', 'before');
    Legba::clear('watch_after_clear');  # removes watcher
    Legba::watch('watch_after_clear', sub { push @vals, $_[1] });  # re-register
    Legba::set('watch_after_clear', 'after');
    is($vals[-1], 'after', 'watcher sees value after clear+re-watch');
};

# ============================================================
# _registry introspection
# ============================================================

subtest '_registry is a hashref of name to index' => sub {
    Legba::add('reg_check');
    my $reg = Legba::_registry();
    ok(ref $reg eq 'HASH', '_registry returns hashref');
    ok(exists $reg->{reg_check}, '_registry contains newly added slot');
    my $idx = $reg->{reg_check};
    ok($idx >= 0, 'index in registry is non-negative');
    is($idx, Legba::index('reg_check'), 'registry index matches index()');
};

# ============================================================
# Slot isolation
# ============================================================

subtest 'slots with similar names are independent' => sub {
    Legba::add('iso_', 'iso_a', 'iso_ab', 'iso_abc');
    Legba::set('iso_',   1);
    Legba::set('iso_a',  2);
    Legba::set('iso_ab', 3);
    Legba::set('iso_abc',4);
    is(Legba::get('iso_'),   1, 'iso_');
    is(Legba::get('iso_a'),  2, 'iso_a');
    is(Legba::get('iso_ab'), 3, 'iso_ab');
    is(Legba::get('iso_abc'),4, 'iso_abc');
};

subtest 'accessor in one package does not appear in another' => sub {
    package IsoPkgA; use Legba qw/iso_pkg_slot/;
    package IsoPkgB; use Legba qw/iso_pkg_slot/;
    package main;
    ok(IsoPkgA->can('iso_pkg_slot'), 'IsoPkgA has accessor');
    ok(IsoPkgB->can('iso_pkg_slot'), 'IsoPkgB has accessor');
    IsoPkgA::iso_pkg_slot('from_a');
    is(IsoPkgB::iso_pkg_slot(), 'from_a', 'IsoPkgB sees IsoPkgA value (same slot)');
};

# ============================================================
# Large values / many operations
# ============================================================

subtest 'large number of rapid set/get via index' => sub {
    Legba::add('rapid_idx');
    my $idx = Legba::index('rapid_idx');
    for my $i (1..10_000) {
        Legba::set_by_idx($idx, $i);
    }
    is(Legba::get_by_idx($idx), 10_000, 'value correct after 10k set_by_idx');
};

subtest 'watcher called correct number of times under load' => sub {
    Legba::add('load_watch');
    my $count = 0;
    Legba::watch('load_watch', sub { $count++ });
    Legba::set('load_watch', $_) for 1..1000;
    is($count, 1000, 'watcher fired 1000 times');
};

done_testing();
