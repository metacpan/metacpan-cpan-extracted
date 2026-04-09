#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Func::Util qw(
    any_cb all_cb none_cb first_cb grep_cb count_cb partition_cb final_cb
    register_callback has_callback list_callbacks
);

# ============================================
# Callback System Integration Tests
# ============================================

subtest 'built-in predicates - numeric' => sub {
    my @numbers = (-5, -2, 0, 1, 3, 5, 8, 10);

    # Test with :is_positive
    ok(any_cb(\@numbers, ':is_positive'), 'any_cb :is_positive');
    ok(!all_cb(\@numbers, ':is_positive'), 'all_cb :is_positive (false)');
    ok(!none_cb(\@numbers, ':is_positive'), 'none_cb :is_positive (false)');

    is(first_cb(\@numbers, ':is_positive'), 1, 'first_cb :is_positive = 1');
    is(final_cb(\@numbers, ':is_positive'), 10, 'final_cb :is_positive = 10');

    my @positive = grep_cb(\@numbers, ':is_positive');
    is_deeply(\@positive, [1, 3, 5, 8, 10], 'grep_cb :is_positive');

    is(count_cb(\@numbers, ':is_positive'), 5, 'count_cb :is_positive = 5');

    my ($pos, $non_pos) = partition_cb(\@numbers, ':is_positive');
    is_deeply($pos, [1, 3, 5, 8, 10], 'partition_cb positive');
    is_deeply($non_pos, [-5, -2, 0], 'partition_cb non-positive');
};

subtest 'built-in predicates - even/odd' => sub {
    my @numbers = (1, 2, 3, 4, 5, 6, 7, 8);

    is(count_cb(\@numbers, ':is_even'), 4, 'count even');
    is(count_cb(\@numbers, ':is_odd'), 4, 'count odd');

    my @evens = grep_cb(\@numbers, ':is_even');
    is_deeply(\@evens, [2, 4, 6, 8], 'grep even');

    is(first_cb(\@numbers, ':is_even'), 2, 'first even');
    is(final_cb(\@numbers, ':is_odd'), 7, 'final odd');
};

subtest 'built-in predicates - zero/negative' => sub {
    my @numbers = (-3, -1, 0, 1, 3);

    ok(any_cb(\@numbers, ':is_zero'), 'any zero');
    is(first_cb(\@numbers, ':is_zero'), 0, 'first zero');

    ok(any_cb(\@numbers, ':is_negative'), 'any negative');
    is(count_cb(\@numbers, ':is_negative'), 2, 'count negative');
};

subtest 'built-in predicates - type checks' => sub {
    my @mixed = (undef, '', 0, 1, 'hello', [], {}, sub {});

    is(count_cb(\@mixed, ':is_defined'), 7, 'count defined');
    is(count_cb(\@mixed, ':is_ref'), 3, 'count refs');
    is(count_cb(\@mixed, ':is_array'), 1, 'count arrays');
    is(count_cb(\@mixed, ':is_hash'), 1, 'count hashes');
    is(count_cb(\@mixed, ':is_code'), 1, 'count coderefs');
};

subtest 'built-in predicates - truthiness' => sub {
    my @values = (undef, '', 0, 1, 'yes', 'false');

    my @truthy = grep_cb(\@values, ':is_true');
    is_deeply(\@truthy, [1, 'yes', 'false'], 'grep truthy');

    my @falsy = grep_cb(\@values, ':is_false');
    is_deeply(\@falsy, [undef, '', 0], 'grep falsy');
};

subtest 'built-in predicates - string checks' => sub {
    my @strings = ('', '   ', 'hello', 'world', undef);

    is(count_cb(\@strings, ':is_empty'), 2, 'count empty (undef + "")');
    is(count_cb(\@strings, ':is_string'), 4, 'count strings');
};

subtest 'callback registry management' => sub {
    # Check built-in callbacks exist
    ok(has_callback(':is_positive'), 'has :is_positive');
    ok(has_callback(':is_negative'), 'has :is_negative');
    ok(has_callback(':is_even'), 'has :is_even');
    ok(has_callback(':is_defined'), 'has :is_defined');

    # List all callbacks
    my $callbacks = list_callbacks();
    ok(ref $callbacks eq 'ARRAY', 'list_callbacks returns arrayref');
    ok(scalar(@$callbacks) > 10, 'many built-in callbacks');

    # Check for expected callbacks in list
    my %cb_set = map { $_ => 1 } @$callbacks;
    ok($cb_set{':is_positive'}, ':is_positive in list');
    ok($cb_set{':is_number'}, ':is_number in list');
};

subtest 'custom callback registration' => sub {
    # Register custom callback
    register_callback('is_large', sub { $_[0] > 100 });

    ok(has_callback('is_large'), 'custom callback registered');

    my @numbers = (50, 100, 150, 200, 75);
    my @large = grep_cb(\@numbers, 'is_large');
    is_deeply(\@large, [150, 200], 'custom callback works');

    is(count_cb(\@numbers, 'is_large'), 2, 'count with custom callback');
};

subtest 'partition_cb use cases' => sub {
    my @students = (
        { name => 'Alice', score => 85 },
        { name => 'Bob', score => 72 },
        { name => 'Carol', score => 91 },
        { name => 'Dave', score => 68 },
    );

    # Register callback for passing grade
    register_callback('passed', sub { $_[0]->{score} >= 75 });

    my ($passed, $failed) = partition_cb(\@students, 'passed');

    is(scalar(@$passed), 2, 'two passed');
    is(scalar(@$failed), 2, 'two failed');

    my @passed_names = map { $_->{name} } @$passed;
    is_deeply([sort @passed_names], ['Alice', 'Carol'], 'correct students passed');
};

subtest 'chaining callbacks' => sub {
    my @data = (-10, -5, 0, 5, 10, 15, 20);

    # Find positive numbers, then partition by even/odd
    my @positive = grep_cb(\@data, ':is_positive');
    my ($evens, $odds) = partition_cb(\@positive, ':is_even');

    is_deeply($evens, [10, 20], 'positive evens');
    is_deeply($odds, [5, 15], 'positive odds');
};

subtest 'all_cb edge cases' => sub {
    # Empty array
    my @empty = ();
    ok(all_cb(\@empty, ':is_positive'), 'all_cb empty = true (vacuous)');

    # Single element
    my @single = (5);
    ok(all_cb(\@single, ':is_positive'), 'all_cb single positive');
    ok(!all_cb(\@single, ':is_negative'), 'all_cb single not negative');
};

subtest 'none_cb edge cases' => sub {
    # Empty array
    my @empty = ();
    ok(none_cb(\@empty, ':is_positive'), 'none_cb empty = true');

    # All fail condition
    my @negatives = (-5, -3, -1);
    ok(none_cb(\@negatives, ':is_positive'), 'none_cb all negative');
};

subtest 'first_cb and final_cb with no match' => sub {
    my @positives = (1, 2, 3);

    my $first_neg = first_cb(\@positives, ':is_negative');
    ok(!defined $first_neg, 'first_cb no match = undef');

    my $final_neg = final_cb(\@positives, ':is_negative');
    ok(!defined $final_neg, 'final_cb no match = undef');
};

subtest 'real-world: data filtering pipeline' => sub {
    my @transactions = (
        { amount => 100, type => 'credit' },
        { amount => -50, type => 'debit' },
        { amount => 200, type => 'credit' },
        { amount => -30, type => 'debit' },
        { amount => 0, type => 'adjustment' },
    );

    # Register callbacks for transaction filtering
    register_callback('is_credit', sub { $_[0]->{type} eq 'credit' });
    register_callback('is_debit', sub { $_[0]->{type} eq 'debit' });
    register_callback('non_zero', sub { $_[0]->{amount} != 0 });

    my @credits = grep_cb(\@transactions, 'is_credit');
    is(scalar(@credits), 2, 'two credits');

    my @debits = grep_cb(\@transactions, 'is_debit');
    is(scalar(@debits), 2, 'two debits');

    my @active = grep_cb(\@transactions, 'non_zero');
    is(scalar(@active), 4, 'four non-zero transactions');

    # Calculate totals
    my $credit_total = 0;
    $credit_total += $_->{amount} for @credits;
    is($credit_total, 300, 'credit total = 300');
};

subtest 'real-world: validation framework' => sub {
    # Register validation callbacks
    register_callback('has_name', sub { defined $_[0]->{name} && length($_[0]->{name}) > 0 });
    register_callback('has_email', sub { defined $_[0]->{email} && $_[0]->{email} =~ /@/ });
    register_callback('adult', sub { defined $_[0]->{age} && $_[0]->{age} >= 18 });

    my @users = (
        { name => 'Alice', email => 'alice@example.com', age => 25 },
        { name => 'Bob', age => 17 },
        { name => '', email => 'anon@example.com', age => 30 },
        { name => 'Carol', email => 'carol@example.com', age => 22 },
    );

    my @with_name = grep_cb(\@users, 'has_name');
    is(scalar(@with_name), 3, 'three have names');

    my @with_email = grep_cb(\@users, 'has_email');
    is(scalar(@with_email), 3, 'three have emails');

    my @adults = grep_cb(\@users, 'adult');
    is(scalar(@adults), 3, 'three adults');

    # Find fully valid users (all conditions)
    my @valid = grep {
        first_cb([$_], 'has_name') &&
        first_cb([$_], 'has_email') &&
        first_cb([$_], 'adult')
    } @users;
    is(scalar(@valid), 2, 'two fully valid users');
};

done_testing();
