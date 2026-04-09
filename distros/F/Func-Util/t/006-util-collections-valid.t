#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    array_len array_first array_last hash_size
    is_empty_array is_empty_hash
    uniq partition pick omit pluck defaults
);

# ============================================
# array_len
# ============================================

subtest 'array_len basic' => sub {
    is(array_len([]), 0, 'array_len: empty');
    is(array_len([1]), 1, 'array_len: single');
    is(array_len([1,2,3]), 3, 'array_len: multiple');
    is(array_len([1..100]), 100, 'array_len: 100 elements');
};

subtest 'array_len edge cases' => sub {
    # With undef elements
    is(array_len([undef, undef, undef]), 3, 'array_len: undef elements');

    # Nested arrays
    is(array_len([[1,2], [3,4]]), 2, 'array_len: nested arrays');

    # Mixed types
    is(array_len([1, 'two', {}, [], sub {}]), 5, 'array_len: mixed types');

    # Non-array returns undef
    is(array_len(undef), undef, 'array_len: undef');
    is(array_len('string'), undef, 'array_len: string');
    is(array_len({}), undef, 'array_len: hash');
};

# ============================================
# array_first
# ============================================

subtest 'array_first basic' => sub {
    is(array_first([1,2,3]), 1, 'array_first: returns first');
    is(array_first(['a','b','c']), 'a', 'array_first: strings');
    is(array_first([0,1,2]), 0, 'array_first: zero');
};

subtest 'array_first edge cases' => sub {
    # Empty array
    is(array_first([]), undef, 'array_first: empty');

    # First element is undef
    is(array_first([undef, 1, 2]), undef, 'array_first: undef element');

    # Single element
    is(array_first([42]), 42, 'array_first: single');

    # Non-array
    is(array_first(undef), undef, 'array_first: undef');
    is(array_first('string'), undef, 'array_first: string');
    is(array_first({}), undef, 'array_first: hash');

    # Nested
    is_deeply(array_first([[1,2], [3,4]]), [1,2], 'array_first: nested');
};

# ============================================
# array_last
# ============================================

subtest 'array_last basic' => sub {
    is(array_last([1,2,3]), 3, 'array_last: returns last');
    is(array_last(['a','b','c']), 'c', 'array_last: strings');
    is(array_last([1,2,0]), 0, 'array_last: zero');
};

subtest 'array_last edge cases' => sub {
    # Empty array
    is(array_last([]), undef, 'array_last: empty');

    # Last element is undef
    is(array_last([1, 2, undef]), undef, 'array_last: undef element');

    # Single element
    is(array_last([42]), 42, 'array_last: single');

    # Non-array
    is(array_last(undef), undef, 'array_last: undef');
    is(array_last('string'), undef, 'array_last: string');
    is(array_last({}), undef, 'array_last: hash');

    # Nested
    is_deeply(array_last([[1,2], [3,4]]), [3,4], 'array_last: nested');
};

# ============================================
# hash_size
# ============================================

subtest 'hash_size basic' => sub {
    is(hash_size({}), 0, 'hash_size: empty');
    is(hash_size({a => 1}), 1, 'hash_size: single');
    is(hash_size({a => 1, b => 2, c => 3}), 3, 'hash_size: multiple');
};

subtest 'hash_size edge cases' => sub {
    # With undef values
    is(hash_size({a => undef, b => undef}), 2, 'hash_size: undef values');

    # Nested hashes
    is(hash_size({a => {b => 1}, c => {d => 2}}), 2, 'hash_size: nested');

    # Non-hash returns undef
    is(hash_size(undef), undef, 'hash_size: undef');
    is(hash_size('string'), undef, 'hash_size: string');
    is(hash_size([]), undef, 'hash_size: array');
};

# ============================================
# is_empty_array
# ============================================

subtest 'is_empty_array basic' => sub {
    ok(is_empty_array([]), 'is_empty_array: empty');
    ok(!is_empty_array([1]), 'is_empty_array: single element');
    ok(!is_empty_array([1,2,3]), 'is_empty_array: multiple');
};

subtest 'is_empty_array edge cases' => sub {
    # Array with undef is not empty
    ok(!is_empty_array([undef]), 'is_empty_array: undef element');

    # Non-array returns false
    ok(!is_empty_array(undef), 'is_empty_array: undef');
    ok(!is_empty_array(''), 'is_empty_array: empty string');
    ok(!is_empty_array({}), 'is_empty_array: hash');
    ok(!is_empty_array(0), 'is_empty_array: zero');
};

# ============================================
# is_empty_hash
# ============================================

subtest 'is_empty_hash basic' => sub {
    ok(is_empty_hash({}), 'is_empty_hash: empty');
    ok(!is_empty_hash({a => 1}), 'is_empty_hash: single key');
    ok(!is_empty_hash({a => 1, b => 2}), 'is_empty_hash: multiple');
};

subtest 'is_empty_hash edge cases' => sub {
    # Hash with undef value is not empty
    ok(!is_empty_hash({a => undef}), 'is_empty_hash: undef value');

    # Non-hash returns false
    ok(!is_empty_hash(undef), 'is_empty_hash: undef');
    ok(!is_empty_hash(''), 'is_empty_hash: empty string');
    ok(!is_empty_hash([]), 'is_empty_hash: array');
    ok(!is_empty_hash(0), 'is_empty_hash: zero');
};

# ============================================
# uniq
# ============================================

subtest 'uniq basic' => sub {
    is_deeply([uniq(1, 2, 3)], [1, 2, 3], 'uniq: no duplicates');
    is_deeply([uniq(1, 1, 2, 2, 3, 3)], [1, 2, 3], 'uniq: all duplicates');
    is_deeply([uniq(1, 2, 1, 3, 2, 1)], [1, 2, 3], 'uniq: scattered duplicates');
};

subtest 'uniq preserves order' => sub {
    is_deeply([uniq(3, 1, 4, 1, 5, 9, 2, 6)], [3, 1, 4, 5, 9, 2, 6], 'uniq: order preserved');
    is_deeply([uniq('c', 'a', 'b', 'a', 'c')], ['c', 'a', 'b'], 'uniq: strings order');
};

subtest 'uniq edge cases' => sub {
    # Empty list
    is_deeply([uniq()], [], 'uniq: empty list');

    # Single element
    is_deeply([uniq(42)], [42], 'uniq: single');

    # All same
    is_deeply([uniq(5, 5, 5, 5, 5)], [5], 'uniq: all same');

    # With undef
    is_deeply([uniq(1, undef, 2, undef, 3)], [1, undef, 2, 3], 'uniq: with undef');

    # Mixed types (stringified for comparison)
    is_deeply([uniq('1', 1, '1')], ['1'], 'uniq: mixed 1 and "1"');

    # Strings
    is_deeply([uniq('a', 'b', 'a', 'c')], ['a', 'b', 'c'], 'uniq: strings');
};

# ============================================
# partition
# ============================================

subtest 'partition basic' => sub {
    # partition takes a LIST and returns an arrayref of two arrayrefs
    my $result = partition(sub { $_ % 2 == 0 }, 1,2,3,4,5,6);
    is_deeply($result->[0], [2,4,6], 'partition: evens');
    is_deeply($result->[1], [1,3,5], 'partition: odds');
};

subtest 'partition edge cases' => sub {
    # Empty list
    my $result = partition(sub { 1 });
    is_deeply($result->[0], [], 'partition: empty pass');
    is_deeply($result->[1], [], 'partition: empty fail');

    # All pass
    $result = partition(sub { 1 }, 1,2,3);
    is_deeply($result->[0], [1,2,3], 'partition: all pass');
    is_deeply($result->[1], [], 'partition: none fail');

    # None pass
    $result = partition(sub { 0 }, 1,2,3);
    is_deeply($result->[0], [], 'partition: none pass');
    is_deeply($result->[1], [1,2,3], 'partition: all fail');

    # With complex predicate
    my @items = (
        {name => 'a', active => 1},
        {name => 'b', active => 0},
        {name => 'c', active => 1},
    );
    $result = partition(sub { $_->{active} }, @items);
    is(scalar @{$result->[0]}, 2, 'partition: complex pass count');
    is(scalar @{$result->[1]}, 1, 'partition: complex fail count');
};

# ============================================
# pick
# ============================================

subtest 'pick basic' => sub {
    my $hash = {a => 1, b => 2, c => 3, d => 4};

    # pick returns hashref in scalar context, use scalar() to force
    is_deeply(scalar(pick($hash, 'a', 'c')), {a => 1, c => 3}, 'pick: specific keys');
    is_deeply(scalar(pick($hash, 'a')), {a => 1}, 'pick: single key');
    is_deeply(scalar(pick($hash, 'a', 'b', 'c', 'd')), {a => 1, b => 2, c => 3, d => 4}, 'pick: all keys');
};

subtest 'pick edge cases' => sub {
    my $hash = {a => 1, b => 2};

    # Missing keys are ignored
    is_deeply(scalar(pick($hash, 'a', 'x', 'y')), {a => 1}, 'pick: missing keys');

    # No keys
    is_deeply(scalar(pick($hash)), {}, 'pick: no keys');

    # Empty hash
    is_deeply(scalar(pick({}, 'a', 'b')), {}, 'pick: empty hash');

    # With undef value - pick only includes keys that exist with defined values
    is_deeply(scalar(pick({a => undef, b => 2}, 'a', 'b')), {b => 2}, 'pick: undef value excluded');
};

# ============================================
# omit
# ============================================

subtest 'omit basic' => sub {
    my $hash = {a => 1, b => 2, c => 3, d => 4};

    # omit returns hashref in scalar context, use scalar() to force
    is_deeply(scalar(omit($hash, 'b', 'd')), {a => 1, c => 3}, 'omit: specific keys');
    is_deeply(scalar(omit($hash, 'a')), {b => 2, c => 3, d => 4}, 'omit: single key');
};

subtest 'omit edge cases' => sub {
    my $hash = {a => 1, b => 2};

    # Missing keys are OK
    is_deeply(scalar(omit($hash, 'x', 'y')), {a => 1, b => 2}, 'omit: missing keys');

    # No keys
    is_deeply(scalar(omit($hash)), {a => 1, b => 2}, 'omit: no keys');

    # All keys
    is_deeply(scalar(omit($hash, 'a', 'b')), {}, 'omit: all keys');

    # Empty hash
    is_deeply(scalar(omit({}, 'a', 'b')), {}, 'omit: empty hash');
};

# ============================================
# pluck
# ============================================

subtest 'pluck basic' => sub {
    my $users = [
        {name => 'alice', age => 30},
        {name => 'bob', age => 25},
        {name => 'charlie', age => 35},
    ];

    # pluck takes an arrayref and returns an arrayref
    is_deeply(pluck($users, 'name'), ['alice', 'bob', 'charlie'], 'pluck: names');
    is_deeply(pluck($users, 'age'), [30, 25, 35], 'pluck: ages');
};

subtest 'pluck edge cases' => sub {
    # Empty array
    is_deeply(pluck([], 'name'), [], 'pluck: empty array');

    # Missing key
    my $data = [{a => 1}, {b => 2}, {a => 3}];
    is_deeply(pluck($data, 'a'), [1, undef, 3], 'pluck: missing key gives undef');

    # Single element
    is_deeply(pluck([{x => 42}], 'x'), [42], 'pluck: single');

    # All missing
    is_deeply(pluck([{a => 1}, {a => 2}], 'b'), [undef, undef], 'pluck: all missing');
};

# ============================================
# defaults
# ============================================

subtest 'defaults basic' => sub {
    my $partial = {a => 1, b => 2};
    my $defs = {b => 99, c => 3, d => 4};

    my $result = defaults($partial, $defs);
    is_deeply($result, {a => 1, b => 2, c => 3, d => 4}, 'defaults: merge');
};

subtest 'defaults edge cases' => sub {
    # Empty partial
    my $result = defaults({}, {a => 1, b => 2});
    is_deeply($result, {a => 1, b => 2}, 'defaults: empty partial');

    # Empty defaults
    $result = defaults({a => 1}, {});
    is_deeply($result, {a => 1}, 'defaults: empty defaults');

    # Both empty
    $result = defaults({}, {});
    is_deeply($result, {}, 'defaults: both empty');

    # Original not modified
    my $orig = {a => 1};
    my $defs = {b => 2};
    $result = defaults($orig, $defs);
    is_deeply($orig, {a => 1}, 'defaults: original unchanged');
    is_deeply($defs, {b => 2}, 'defaults: defaults unchanged');

    # With undef value in partial - undef is treated as "missing"
    $result = defaults({a => undef}, {a => 1, b => 2});
    is_deeply($result, {a => 1, b => 2}, 'defaults: undef gets default value');
};

# ============================================
# Combined tests
# ============================================

subtest 'collection function combinations' => sub {
    my @users = (
        {name => 'alice', age => 30, active => 1},
        {name => 'bob', age => 25, active => 0},
        {name => 'charlie', age => 35, active => 1},
        {name => 'diana', age => 28, active => 1},
    );

    # Get unique ages of active users
    my $partitioned = partition(sub { $_->{active} }, @users);
    my $active = $partitioned->[0];
    my $inactive = $partitioned->[1];
    my $ages = pluck($active, 'age');
    is_deeply([sort {$a <=> $b} uniq(@$ages)], [28, 30, 35], 'combined: unique active ages');

    # Array/hash size checks
    is(array_len($active), 3, 'combined: active count');
    is(array_len($inactive), 1, 'combined: inactive count');

    # Pick specific fields
    my $first_active = array_first($active);
    my $public = pick($first_active, 'name', 'age');
    is_deeply([sort keys %$public], ['age', 'name'], 'combined: picked keys');
};

done_testing;
