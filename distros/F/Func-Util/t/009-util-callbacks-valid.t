#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');

# util functions are accessed via fully-qualified names since XSLoader
# doesn't set up Exporter
*register_callback = \&Func::Util::register_callback;
*has_callback = \&Func::Util::has_callback;
*list_callbacks = \&Func::Util::list_callbacks;
*any_cb = \&Func::Util::any_cb;
*all_cb = \&Func::Util::all_cb;
*none_cb = \&Func::Util::none_cb;
*first_cb = \&Func::Util::first_cb;
*grep_cb = \&Func::Util::grep_cb;
*count_cb = \&Func::Util::count_cb;
*partition_cb = \&Func::Util::partition_cb;
*final_cb = \&Func::Util::final_cb;

# ============================================
# Built-in predicates (prefixed with :)
# ============================================

subtest 'built-in predicate :is_defined' => sub {
    my $data = [1, undef, 2, undef, 3];

    ok(any_cb($data, ':is_defined'), 'any_cb :is_defined');
    ok(!all_cb($data, ':is_defined'), 'all_cb :is_defined - has undefs');
    ok(!none_cb($data, ':is_defined'), 'none_cb :is_defined - has defined');
    is(first_cb($data, ':is_defined'), 1, 'first_cb :is_defined');
    is(count_cb($data, ':is_defined'), 3, 'count_cb :is_defined');
    is_deeply([grep_cb($data, ':is_defined')], [1, 2, 3], 'grep_cb :is_defined');
};

subtest 'built-in predicate :is_true' => sub {
    my $data = [1, 0, 'hello', '', undef, 42];

    is(count_cb($data, ':is_true'), 3, 'count_cb :is_true');
    is(first_cb($data, ':is_true'), 1, 'first_cb :is_true');
    is_deeply([grep_cb($data, ':is_true')], [1, 'hello', 42], 'grep_cb :is_true');
};

subtest 'built-in predicate :is_false' => sub {
    my $data = [1, 0, 'hello', '', undef, 42];

    is(count_cb($data, ':is_false'), 3, 'count_cb :is_false');
    is(first_cb($data, ':is_false'), 0, 'first_cb :is_false');
    is_deeply([grep_cb($data, ':is_false')], [0, '', undef], 'grep_cb :is_false');
};

subtest 'built-in predicate :is_positive' => sub {
    my $data = [-5, 0, 5, -10, 10, 0];

    is(count_cb($data, ':is_positive'), 2, 'count_cb :is_positive');
    is(first_cb($data, ':is_positive'), 5, 'first_cb :is_positive');
    ok(any_cb($data, ':is_positive'), 'any_cb :is_positive');
    ok(!all_cb($data, ':is_positive'), 'all_cb :is_positive');
};

subtest 'built-in predicate :is_negative' => sub {
    my $data = [-5, 0, 5, -10, 10, 0];

    is(count_cb($data, ':is_negative'), 2, 'count_cb :is_negative');
    is(first_cb($data, ':is_negative'), -5, 'first_cb :is_negative');
    is_deeply([grep_cb($data, ':is_negative')], [-5, -10], 'grep_cb :is_negative');
};

subtest 'built-in predicate :is_zero' => sub {
    my $data = [-5, 0, 5, -10, 10, 0];

    is(count_cb($data, ':is_zero'), 2, 'count_cb :is_zero');
    is(first_cb($data, ':is_zero'), 0, 'first_cb :is_zero');
};

subtest 'built-in predicate :is_even' => sub {
    my $data = [1, 2, 3, 4, 5, 6, 7, 8];

    is(count_cb($data, ':is_even'), 4, 'count_cb :is_even');
    is(first_cb($data, ':is_even'), 2, 'first_cb :is_even');
    is_deeply([grep_cb($data, ':is_even')], [2, 4, 6, 8], 'grep_cb :is_even');
};

subtest 'built-in predicate :is_odd' => sub {
    my $data = [1, 2, 3, 4, 5, 6, 7, 8];

    is(count_cb($data, ':is_odd'), 4, 'count_cb :is_odd');
    is(first_cb($data, ':is_odd'), 1, 'first_cb :is_odd');
    is_deeply([grep_cb($data, ':is_odd')], [1, 3, 5, 7], 'grep_cb :is_odd');
};

subtest 'built-in predicate :is_ref' => sub {
    my $data = [1, [], 'string', {}, sub {}, undef];

    is(count_cb($data, ':is_ref'), 3, 'count_cb :is_ref');
    is_deeply(first_cb($data, ':is_ref'), [], 'first_cb :is_ref');
};

subtest 'built-in predicate :is_array' => sub {
    my $data = [[], {}, 'string', [1,2], {}];

    is(count_cb($data, ':is_array'), 2, 'count_cb :is_array');
};

subtest 'built-in predicate :is_hash' => sub {
    my $data = [[], {}, 'string', [1,2], {a => 1}];

    is(count_cb($data, ':is_hash'), 2, 'count_cb :is_hash');
};

# ============================================
# partition_cb
# ============================================

subtest 'partition_cb basic' => sub {
    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    my ($evens, $odds) = partition_cb($nums, ':is_even');
    is_deeply($evens, [2, 4, 6, 8, 10], 'partition_cb: evens');
    is_deeply($odds, [1, 3, 5, 7, 9], 'partition_cb: odds');
};

subtest 'partition_cb edge cases' => sub {
    # Empty array
    my ($pass, $fail) = partition_cb([], ':is_positive');
    is_deeply($pass, [], 'partition_cb: empty pass');
    is_deeply($fail, [], 'partition_cb: empty fail');

    # All pass
    ($pass, $fail) = partition_cb([2, 4, 6], ':is_even');
    is_deeply($pass, [2, 4, 6], 'partition_cb: all pass');
    is_deeply($fail, [], 'partition_cb: none fail');

    # None pass
    ($pass, $fail) = partition_cb([1, 3, 5], ':is_even');
    is_deeply($pass, [], 'partition_cb: none pass');
    is_deeply($fail, [1, 3, 5], 'partition_cb: all fail');
};

# ============================================
# final_cb
# ============================================

subtest 'final_cb basic' => sub {
    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    is(final_cb($nums, ':is_even'), 10, 'final_cb: last even');
    is(final_cb($nums, ':is_odd'), 9, 'final_cb: last odd');
    is(final_cb($nums, ':is_negative'), undef, 'final_cb: no match');
};

subtest 'final_cb edge cases' => sub {
    is(final_cb([], ':is_positive'), undef, 'final_cb: empty array');
    is(final_cb([42], ':is_positive'), 42, 'final_cb: single match');
    is(final_cb([42], ':is_negative'), undef, 'final_cb: single no match');
};

# ============================================
# all_cb / none_cb edge cases
# ============================================

subtest 'all_cb edge cases' => sub {
    # Empty array - vacuous truth
    ok(all_cb([], ':is_positive'), 'all_cb: empty is true');

    # All match
    ok(all_cb([2, 4, 6, 8], ':is_even'), 'all_cb: all even');

    # One fails
    ok(!all_cb([2, 4, 5, 8], ':is_even'), 'all_cb: one odd fails');
};

subtest 'none_cb edge cases' => sub {
    # Empty array
    ok(none_cb([], ':is_positive'), 'none_cb: empty is true');

    # None match
    ok(none_cb([1, 3, 5, 7], ':is_even'), 'none_cb: no evens');

    # One matches
    ok(!none_cb([1, 3, 4, 7], ':is_even'), 'none_cb: one even fails');
};

# ============================================
# Custom callback registration
# ============================================

subtest 'register_callback basic' => sub {
    # Register a custom callback
    register_callback('divisible_by_3', sub { $_[0] % 3 == 0 });

    ok(has_callback('divisible_by_3'), 'has_callback: registered');
    ok(!has_callback('nonexistent'), 'has_callback: not registered');

    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9];
    is(count_cb($nums, 'divisible_by_3'), 3, 'count_cb: custom callback');
    is_deeply([grep_cb($nums, 'divisible_by_3')], [3, 6, 9], 'grep_cb: custom callback');
};

subtest 'register_callback multiple' => sub {
    register_callback('greater_than_5', sub { $_[0] > 5 });
    register_callback('less_than_8', sub { $_[0] < 8 });

    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    is_deeply([grep_cb($nums, 'greater_than_5')], [6, 7, 8, 9, 10], 'grep_cb: > 5');
    is_deeply([grep_cb($nums, 'less_than_8')], [1, 2, 3, 4, 5, 6, 7], 'grep_cb: < 8');
};

subtest 'list_callbacks' => sub {
    my $callbacks = list_callbacks();
    ok(ref($callbacks) eq 'ARRAY', 'list_callbacks: returns arrayref');

    # Should include built-ins
    my %cb_hash = map { $_ => 1 } @$callbacks;
    ok($cb_hash{':is_defined'}, 'list_callbacks: has :is_defined');
    ok($cb_hash{':is_positive'}, 'list_callbacks: has :is_positive');
    ok($cb_hash{':is_even'}, 'list_callbacks: has :is_even');

    # Should include our custom ones
    ok($cb_hash{'divisible_by_3'}, 'list_callbacks: has divisible_by_3');
    ok($cb_hash{'greater_than_5'}, 'list_callbacks: has greater_than_5');
};

# ============================================
# Combining predicates
# ============================================

subtest 'multiple predicate checks' => sub {
    my $data = [-10, -5, 0, 5, 10];

    # Check positive - grep_cb returns a list
    my @positives = grep_cb($data, ':is_positive');
    is_deeply(\@positives, [5, 10], 'grep positive');

    # Check negative
    my @negatives = grep_cb($data, ':is_negative');
    is_deeply(\@negatives, [-10, -5], 'grep negative');

    # Check zero
    my @zeros = grep_cb($data, ':is_zero');
    is_deeply(\@zeros, [0], 'grep zero');

    # Verify all accounted for
    is(scalar(@positives) + scalar(@negatives) + scalar(@zeros), 5, 'all elements categorized');
};

subtest 'string predicates' => sub {
    my $data = ['hello', '', 'world', undef, '  ', 'test'];

    # :is_empty checks for undef or empty string
    is(count_cb($data, ':is_empty'), 2, 'count_cb :is_empty (empty string + undef)');

    # :is_nonempty is the opposite
    is(count_cb($data, ':is_nonempty'), 4, 'count_cb :is_nonempty');

    # :is_string checks for defined non-ref (includes empty string)
    is(count_cb($data, ':is_string'), 5, 'count_cb :is_string');
};

# ============================================
# Edge cases with mixed data
# ============================================

subtest 'mixed data types' => sub {
    my $mixed = [
        1,
        'string',
        [],
        {},
        sub {},
        undef,
        0,
        '',
        3.14,
    ];

    # Count refs
    is(count_cb($mixed, ':is_ref'), 3, 'mixed: refs');

    # Count defined
    is(count_cb($mixed, ':is_defined'), 8, 'mixed: defined');

    # Count true
    is(count_cb($mixed, ':is_true'), 6, 'mixed: true values');

    # Count false
    is(count_cb($mixed, ':is_false'), 3, 'mixed: false values (0, "", undef)');
};

done_testing;
