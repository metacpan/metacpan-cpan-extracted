#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Legba');

# Test 1: basic watcher fires on set
subtest 'watcher fires on set' => sub {
    plan tests => 3;

    Legba::add('watch1');
    my @fired;
    Legba::watch('watch1', sub { push @fired, [@_] });

    Legba::set('watch1', 'hello');
    is(scalar @fired, 1, 'watcher fired once');
    is($fired[0][0], 'watch1', 'watcher receives slot name');
    is($fired[0][1], 'hello',  'watcher receives new value');
};

# Test 2: watcher fires via imported accessor
subtest 'watcher fires via accessor' => sub {
    plan tests => 2;

    package WatchPkg;
    use Legba qw/wpkg_slot/;
    package main;

    my @calls;
    Legba::watch('wpkg_slot', sub { push @calls, $_[1] });

    WatchPkg::wpkg_slot('from accessor');
    is(scalar @calls, 1,              'watcher fired via accessor');
    is($calls[0],    'from accessor', 'correct value');
};

# Test 3: multiple watchers all fire
subtest 'multiple watchers' => sub {
    plan tests => 2;

    Legba::add('multi_watch');
    my (@a, @b);
    Legba::watch('multi_watch', sub { push @a, $_[1] });
    Legba::watch('multi_watch', sub { push @b, $_[1] });

    Legba::set('multi_watch', 42);
    is(scalar @a, 1, 'first watcher fired');
    is(scalar @b, 1, 'second watcher fired');
};

# Test 4: unwatch all
subtest 'unwatch all' => sub {
    plan tests => 2;

    Legba::add('unwatch_all');
    my @calls;
    Legba::watch('unwatch_all', sub { push @calls, 1 });

    Legba::set('unwatch_all', 1);
    is(scalar @calls, 1, 'watcher fires before unwatch');

    Legba::unwatch('unwatch_all');
    Legba::set('unwatch_all', 2);
    is(scalar @calls, 1, 'watcher does not fire after unwatch');
};

# Test 5: unwatch specific callback
subtest 'unwatch specific' => sub {
    plan tests => 3;

    Legba::add('unwatch_one');
    my (@a, @b);
    my $cb1 = sub { push @a, 1 };
    my $cb2 = sub { push @b, 1 };
    Legba::watch('unwatch_one', $cb1);
    Legba::watch('unwatch_one', $cb2);

    Legba::set('unwatch_one', 1);
    is(scalar @a, 1, 'both fire before unwatch');

    Legba::unwatch('unwatch_one', $cb1);
    Legba::set('unwatch_one', 2);
    is(scalar @a, 1, 'cb1 removed');
    is(scalar @b, 2, 'cb2 still fires');
};

# Test 6: watcher fired on every set, including same value
subtest 'watcher fires on every set' => sub {
    plan tests => 1;

    Legba::add('always_fire');
    my $count = 0;
    Legba::watch('always_fire', sub { $count++ });

    Legba::set('always_fire', 1);
    Legba::set('always_fire', 1);
    Legba::set('always_fire', 1);
    is($count, 3, 'fires every time even with same value');
};

# Test 7: clear removes watchers
subtest 'clear removes watchers' => sub {
    plan tests => 2;

    Legba::add('clear_watch');
    my $count = 0;
    Legba::watch('clear_watch', sub { $count++ });

    Legba::set('clear_watch', 'x');
    is($count, 1, 'fires before clear');

    Legba::clear('clear_watch');
    Legba::set('clear_watch', 'y');
    is($count, 1, 'does not fire after clear');
};

# Test 8: set_by_idx fires watcher
subtest 'set_by_idx fires watcher' => sub {
    plan tests => 1;

    Legba::add('byidx_watch');
    my $idx = Legba::index('byidx_watch');
    my @calls;
    Legba::watch('byidx_watch', sub { push @calls, $_[1] });

    Legba::set_by_idx($idx, 'indexed');
    is($calls[0], 'indexed', 'watcher fires via set_by_idx');
};

done_testing();
