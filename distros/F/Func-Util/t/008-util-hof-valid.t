#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    first any all none
    final
    first_gt first_lt first_ge first_le first_eq first_ne
    final_gt final_lt final_ge final_le final_eq final_ne
    any_gt any_lt any_ge any_le any_eq any_ne
    all_gt all_lt all_ge all_le all_eq all_ne
    none_gt none_lt none_ge none_le none_eq none_ne
);

# Note: Func::Util::count is for counting substrings, not list elements.
# For list counting with callbacks, use count_cb with named predicates.

# Note: first/any/all/none/count take a LIST (not arrayref)
# The specialized predicates (*_gt, *_lt, etc.) take an ARRAYREF

# ============================================
# first - find first matching element
# ============================================

subtest 'first basic' => sub {
    my @nums = (1, 2, 3, 4, 5);

    is(first(sub { $_ > 3 }, @nums), 4, 'first: > 3');
    is(first(sub { $_ == 1 }, @nums), 1, 'first: == 1');
    is(first(sub { $_ == 5 }, @nums), 5, 'first: == 5');
    is(first(sub { $_ > 10 }, @nums), undef, 'first: no match');
};

subtest 'first edge cases' => sub {
    # Empty list
    is(first(sub { 1 }), undef, 'first: empty list');

    # Single element
    is(first(sub { 1 }, 42), 42, 'first: single match');
    is(first(sub { 0 }, 42), undef, 'first: single no match');

    # First element matches
    is(first(sub { $_ == 1 }, 1, 2, 3), 1, 'first: first element');

    # With hashes
    my @users = (
        {name => 'alice', age => 30},
        {name => 'bob', age => 25},
        {name => 'charlie', age => 35},
    );
    my $found = first(sub { $_->{age} > 28 }, @users);
    is($found->{name}, 'alice', 'first: hash predicate');

    # Finding undef element
    my $result = first(sub { !defined $_ }, undef, 1, 2);
    is($result, undef, 'first: finds undef');
};

# ============================================
# any - true if any match
# ============================================

subtest 'any basic' => sub {
    my @nums = (1, 2, 3, 4, 5);

    ok(any(sub { $_ > 3 }, @nums), 'any: some > 3');
    ok(any(sub { $_ == 1 }, @nums), 'any: one == 1');
    ok(!any(sub { $_ > 10 }, @nums), 'any: none > 10');
};

subtest 'any edge cases' => sub {
    # Empty list
    ok(!any(sub { 1 }), 'any: empty list is false');

    # Single element
    ok(any(sub { 1 }, 42), 'any: single match');
    ok(!any(sub { 0 }, 42), 'any: single no match');

    # All match
    ok(any(sub { $_ > 0 }, 1, 2, 3), 'any: all match still true');

    # First element matches (short-circuit)
    my $count = 0;
    any(sub { $count++; $_ == 1 }, 1, 2, 3, 4, 5);
    is($count, 1, 'any: short-circuits on first match');
};

# ============================================
# all - true if all match
# ============================================

subtest 'all basic' => sub {
    my @nums = (1, 2, 3, 4, 5);

    ok(all(sub { $_ > 0 }, @nums), 'all: all > 0');
    ok(!all(sub { $_ > 3 }, @nums), 'all: not all > 3');
    ok(all(sub { $_ < 10 }, @nums), 'all: all < 10');
};

subtest 'all edge cases' => sub {
    # Empty list - vacuous truth
    ok(all(sub { 0 }), 'all: empty list is true (vacuous)');

    # Single element
    ok(all(sub { 1 }, 42), 'all: single match');
    ok(!all(sub { 0 }, 42), 'all: single no match');

    # First element fails (short-circuit)
    my $count = 0;
    all(sub { $count++; $_ > 1 }, 1, 2, 3, 4, 5);
    is($count, 1, 'all: short-circuits on first fail');
};

# ============================================
# none - true if none match
# ============================================

subtest 'none basic' => sub {
    my @nums = (1, 2, 3, 4, 5);

    ok(none(sub { $_ > 10 }, @nums), 'none: none > 10');
    ok(!none(sub { $_ > 3 }, @nums), 'none: some > 3');
    ok(none(sub { $_ < 0 }, @nums), 'none: none < 0');
};

subtest 'none edge cases' => sub {
    # Empty list
    ok(none(sub { 1 }), 'none: empty list is true');

    # Single element
    ok(none(sub { 0 }, 42), 'none: single no match');
    ok(!none(sub { 1 }, 42), 'none: single match');

    # First element matches (short-circuit)
    my $count = 0;
    none(sub { $count++; $_ == 1 }, 1, 2, 3, 4, 5);
    is($count, 1, 'none: short-circuits on first match');
};

# ============================================
# final - find last matching element (takes arrayref)
# ============================================

subtest 'final basic' => sub {
    my $nums = [1, 2, 3, 4, 5];

    is(final(sub { $_ > 3 }, $nums), 5, 'final: last > 3');
    is(final(sub { $_ < 3 }, $nums), 2, 'final: last < 3');
    is(final(sub { $_ > 10 }, $nums), undef, 'final: no match');
};

subtest 'final edge cases' => sub {
    # Empty array
    is(final(sub { 1 }, []), undef, 'final: empty array');

    # Single element
    is(final(sub { 1 }, [42]), 42, 'final: single match');
    is(final(sub { 0 }, [42]), undef, 'final: single no match');

    # All match - returns last
    is(final(sub { 1 }, [1, 2, 3]), 3, 'final: all match returns last');

    # Multiple matches
    is(final(sub { $_ % 2 == 0 }, [1, 2, 3, 4, 5, 6]), 6, 'final: last even');
};

# ============================================
# first_* specialized predicates (take ARRAYREF)
# ============================================

subtest 'first_gt basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(first_gt($nums, 25), 30, 'first_gt: > 25');
    is(first_gt($nums, 5), 10, 'first_gt: > 5 (first element)');
    is(first_gt($nums, 50), undef, 'first_gt: > 50 (no match)');
    is(first_gt($nums, 100), undef, 'first_gt: > 100');
};

subtest 'first_ge basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(first_ge($nums, 30), 30, 'first_ge: >= 30 (exact)');
    is(first_ge($nums, 25), 30, 'first_ge: >= 25');
    is(first_ge($nums, 10), 10, 'first_ge: >= 10 (first)');
    is(first_ge($nums, 51), undef, 'first_ge: >= 51 (no match)');
};

subtest 'first_lt basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(first_lt($nums, 25), 10, 'first_lt: < 25');
    is(first_lt($nums, 50), 10, 'first_lt: < 50');
    is(first_lt($nums, 10), undef, 'first_lt: < 10 (no match)');
};

subtest 'first_le basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(first_le($nums, 10), 10, 'first_le: <= 10 (exact)');
    is(first_le($nums, 25), 10, 'first_le: <= 25');
    is(first_le($nums, 9), undef, 'first_le: <= 9 (no match)');
};

subtest 'first_eq basic' => sub {
    my $nums = [10, 20, 30, 20, 40];

    is(first_eq($nums, 20), 20, 'first_eq: == 20');
    is(first_eq($nums, 10), 10, 'first_eq: == 10');
    is(first_eq($nums, 99), undef, 'first_eq: == 99 (no match)');
};

subtest 'first_ne basic' => sub {
    my $nums = [10, 10, 10, 20, 30];

    is(first_ne($nums, 10), 20, 'first_ne: != 10');
    is(first_ne($nums, 20), 10, 'first_ne: != 20');
    is(first_ne([5, 5, 5], 5), undef, 'first_ne: all same (no match)');
};

# ============================================
# first_* with hash field
# ============================================

subtest 'first_* with hash field' => sub {
    my $users = [
        {name => 'alice', age => 25},
        {name => 'bob', age => 30},
        {name => 'charlie', age => 35},
    ];

    my $found = first_gt($users, 'age', 28);
    is($found->{name}, 'bob', 'first_gt: hash field');

    $found = first_ge($users, 'age', 30);
    is($found->{name}, 'bob', 'first_ge: hash field');

    $found = first_lt($users, 'age', 30);
    is($found->{name}, 'alice', 'first_lt: hash field');

    $found = first_eq($users, 'age', 35);
    is($found->{name}, 'charlie', 'first_eq: hash field');
};

# ============================================
# final_* specialized predicates
# ============================================

subtest 'final_gt basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(final_gt($nums, 25), 50, 'final_gt: last > 25');
    is(final_gt($nums, 45), 50, 'final_gt: last > 45');
    is(final_gt($nums, 50), undef, 'final_gt: > 50 (no match)');
};

subtest 'final_lt basic' => sub {
    my $nums = [10, 20, 30, 40, 50];

    is(final_lt($nums, 35), 30, 'final_lt: last < 35');
    is(final_lt($nums, 25), 20, 'final_lt: last < 25');
    is(final_lt($nums, 10), undef, 'final_lt: < 10 (no match)');
};

subtest 'final_* with hash field' => sub {
    my $users = [
        {name => 'alice', age => 25},
        {name => 'bob', age => 30},
        {name => 'charlie', age => 28},
    ];

    my $found = final_gt($users, 'age', 26);
    is($found->{name}, 'charlie', 'final_gt: last age > 26');

    $found = final_lt($users, 'age', 30);
    is($found->{name}, 'charlie', 'final_lt: last age < 30');
};

# ============================================
# any_* specialized predicates
# ============================================

subtest 'any_gt basic' => sub {
    my $nums = [10, 20, 30];

    ok(any_gt($nums, 25), 'any_gt: some > 25');
    ok(any_gt($nums, 5), 'any_gt: some > 5');
    ok(!any_gt($nums, 30), 'any_gt: none > 30');
    ok(!any_gt($nums, 100), 'any_gt: none > 100');
};

subtest 'any_lt basic' => sub {
    my $nums = [10, 20, 30];

    ok(any_lt($nums, 25), 'any_lt: some < 25');
    ok(!any_lt($nums, 10), 'any_lt: none < 10');
    ok(!any_lt($nums, 5), 'any_lt: none < 5');
};

subtest 'any_eq basic' => sub {
    my $nums = [10, 20, 30];

    ok(any_eq($nums, 20), 'any_eq: some == 20');
    ok(!any_eq($nums, 25), 'any_eq: none == 25');
};

subtest 'any_* with hash field' => sub {
    my $users = [
        {name => 'alice', age => 25},
        {name => 'bob', age => 30},
    ];

    ok(any_gt($users, 'age', 28), 'any_gt: some age > 28');
    ok(!any_gt($users, 'age', 30), 'any_gt: none age > 30');
};

# ============================================
# all_* specialized predicates
# ============================================

subtest 'all_gt basic' => sub {
    my $nums = [10, 20, 30];

    ok(all_gt($nums, 5), 'all_gt: all > 5');
    ok(!all_gt($nums, 10), 'all_gt: not all > 10');
    ok(!all_gt($nums, 25), 'all_gt: not all > 25');
};

subtest 'all_ge basic' => sub {
    my $nums = [10, 20, 30];

    ok(all_ge($nums, 10), 'all_ge: all >= 10');
    ok(!all_ge($nums, 15), 'all_ge: not all >= 15');
};

subtest 'all_lt basic' => sub {
    my $nums = [10, 20, 30];

    ok(all_lt($nums, 35), 'all_lt: all < 35');
    ok(!all_lt($nums, 30), 'all_lt: not all < 30');
};

subtest 'all_* with hash field' => sub {
    my $users = [
        {name => 'alice', age => 25},
        {name => 'bob', age => 30},
    ];

    ok(all_ge($users, 'age', 25), 'all_ge: all age >= 25');
    ok(!all_ge($users, 'age', 26), 'all_ge: not all age >= 26');
};

subtest 'all_* empty array' => sub {
    # Vacuous truth for empty arrays
    ok(all_gt([], 100), 'all_gt: empty array is true');
    ok(all_lt([], 0), 'all_lt: empty array is true');
    ok(all_eq([], 999), 'all_eq: empty array is true');
};

# ============================================
# none_* specialized predicates
# ============================================

subtest 'none_gt basic' => sub {
    my $nums = [10, 20, 30];

    ok(none_gt($nums, 30), 'none_gt: none > 30');
    ok(none_gt($nums, 100), 'none_gt: none > 100');
    ok(!none_gt($nums, 25), 'none_gt: some > 25');
};

subtest 'none_lt basic' => sub {
    my $nums = [10, 20, 30];

    ok(none_lt($nums, 10), 'none_lt: none < 10');
    ok(none_lt($nums, 5), 'none_lt: none < 5');
    ok(!none_lt($nums, 25), 'none_lt: some < 25');
};

subtest 'none_eq basic' => sub {
    my $nums = [10, 20, 30];

    ok(none_eq($nums, 25), 'none_eq: none == 25');
    ok(!none_eq($nums, 20), 'none_eq: some == 20');
};

subtest 'none_* with hash field' => sub {
    my $users = [
        {name => 'alice', age => 25},
        {name => 'bob', age => 30},
    ];

    ok(none_lt($users, 'age', 25), 'none_lt: none age < 25');
    ok(!none_lt($users, 'age', 30), 'none_lt: some age < 30');
};

# ============================================
# Edge cases across all HOF
# ============================================

subtest 'empty list/array behavior' => sub {
    # List-based functions with empty list
    is(first(sub { 1 }), undef, 'first: empty undef');
    ok(!any(sub { 1 }), 'any: empty false');
    ok(all(sub { 0 }), 'all: empty true (vacuous)');
    ok(none(sub { 1 }), 'none: empty true');

    # Arrayref-based functions (final, specialized predicates)
    my $empty = [];
    is(final(sub { 1 }, $empty), undef, 'final: empty undef');
    is(first_gt($empty, 0), undef, 'first_gt: empty');
    is(final_gt($empty, 0), undef, 'final_gt: empty');
    ok(!any_gt($empty, 0), 'any_gt: empty false');
    ok(all_gt($empty, 100), 'all_gt: empty true');
    ok(none_gt($empty, 0), 'none_gt: empty true');
};

subtest 'single element behavior' => sub {
    # List-based
    is(first(sub { $_ == 42 }, 42), 42, 'first: single match');
    ok(any(sub { $_ == 42 }, 42), 'any: single match');
    ok(all(sub { $_ == 42 }, 42), 'all: single match');
    ok(none(sub { $_ == 0 }, 42), 'none: single no match');

    # Arrayref-based
    my $single = [42];
    is(final(sub { 1 }, $single), 42, 'final: single');
    is(first_eq($single, 42), 42, 'first_eq: single');
    is(final_eq($single, 42), 42, 'final_eq: single');
    ok(any_eq($single, 42), 'any_eq: single');
    ok(all_eq($single, 42), 'all_eq: single');
    ok(none_ne($single, 42), 'none_ne: single');
};

done_testing;
