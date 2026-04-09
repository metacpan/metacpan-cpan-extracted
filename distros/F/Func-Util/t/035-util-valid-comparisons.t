#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Func::Util qw(
    first_gt first_lt first_ge first_le first_eq first_ne
    final_gt final_lt final_ge final_le final_eq final_ne
    any_gt any_lt any_ge any_le any_eq any_ne
    all_gt all_lt all_ge all_le all_eq all_ne
    none_gt none_lt none_ge none_le none_eq none_ne
);

# ============================================
# Comparison Predicates Integration Tests
# Note: All functions take (\@array, $threshold) - arrayref first!
# ============================================

my @numbers = (1, 3, 5, 7, 9, 11, 13, 15);
my @with_dupes = (1, 3, 3, 5, 5, 5, 7, 9);

# ============================================
# first_* - find first matching element
# ============================================

subtest 'first_gt - first greater than' => sub {
    is(first_gt(\@numbers, 5), 7, 'first > 5 is 7');
    is(first_gt(\@numbers, 0), 1, 'first > 0 is 1');
    is(first_gt(\@numbers, 14), 15, 'first > 14 is 15');
    ok(!defined first_gt(\@numbers, 15), 'first > 15 is undef');
    ok(!defined first_gt(\@numbers, 100), 'first > 100 is undef');
};

subtest 'first_lt - first less than' => sub {
    is(first_lt(\@numbers, 10), 1, 'first < 10 is 1');
    is(first_lt(\@numbers, 5), 1, 'first < 5 is 1');
    is(first_lt(\@numbers, 2), 1, 'first < 2 is 1');
    ok(!defined first_lt(\@numbers, 1), 'first < 1 is undef');
    ok(!defined first_lt(\@numbers, 0), 'first < 0 is undef');
};

subtest 'first_ge - first greater or equal' => sub {
    is(first_ge(\@numbers, 5), 5, 'first >= 5 is 5');
    is(first_ge(\@numbers, 6), 7, 'first >= 6 is 7');
    is(first_ge(\@numbers, 1), 1, 'first >= 1 is 1');
    is(first_ge(\@numbers, 15), 15, 'first >= 15 is 15');
    ok(!defined first_ge(\@numbers, 16), 'first >= 16 is undef');
};

subtest 'first_le - first less or equal' => sub {
    is(first_le(\@numbers, 5), 1, 'first <= 5 is 1');
    is(first_le(\@numbers, 15), 1, 'first <= 15 is 1');
    is(first_le(\@numbers, 1), 1, 'first <= 1 is 1');
    ok(!defined first_le(\@numbers, 0), 'first <= 0 is undef');
};

subtest 'first_eq - first equal' => sub {
    is(first_eq(\@numbers, 5), 5, 'first == 5 is 5');
    is(first_eq(\@numbers, 1), 1, 'first == 1 is 1');
    is(first_eq(\@numbers, 15), 15, 'first == 15 is 15');
    ok(!defined first_eq(\@numbers, 2), 'first == 2 is undef');
    ok(!defined first_eq(\@numbers, 100), 'first == 100 is undef');
};

subtest 'first_ne - first not equal' => sub {
    is(first_ne(\@numbers, 1), 3, 'first != 1 is 3');
    is(first_ne(\@numbers, 100), 1, 'first != 100 is 1');
};

# ============================================
# final_* - find last matching element
# ============================================

subtest 'final_gt - last greater than' => sub {
    is(final_gt(\@numbers, 5), 15, 'last > 5 is 15');
    is(final_gt(\@numbers, 10), 15, 'last > 10 is 15');
    is(final_gt(\@numbers, 14), 15, 'last > 14 is 15');
    ok(!defined final_gt(\@numbers, 15), 'last > 15 is undef');
};

subtest 'final_lt - last less than' => sub {
    is(final_lt(\@numbers, 10), 9, 'last < 10 is 9');
    is(final_lt(\@numbers, 15), 13, 'last < 15 is 13');
    is(final_lt(\@numbers, 100), 15, 'last < 100 is 15');
    ok(!defined final_lt(\@numbers, 1), 'last < 1 is undef');
};

subtest 'final_ge - last greater or equal' => sub {
    is(final_ge(\@numbers, 5), 15, 'last >= 5 is 15');
    is(final_ge(\@numbers, 15), 15, 'last >= 15 is 15');
    ok(!defined final_ge(\@numbers, 16), 'last >= 16 is undef');
};

subtest 'final_le - last less or equal' => sub {
    is(final_le(\@numbers, 10), 9, 'last <= 10 is 9');
    is(final_le(\@numbers, 9), 9, 'last <= 9 is 9');
    is(final_le(\@numbers, 100), 15, 'last <= 100 is 15');
};

subtest 'final_eq - last equal' => sub {
    is(final_eq(\@with_dupes, 5), 5, 'last == 5 with dupes');
    is(final_eq(\@with_dupes, 3), 3, 'last == 3 with dupes');
    ok(!defined final_eq(\@numbers, 2), 'last == 2 is undef');
};

subtest 'final_ne - last not equal' => sub {
    is(final_ne(\@numbers, 15), 13, 'last != 15 is 13');
    is(final_ne(\@numbers, 100), 15, 'last != 100 is 15');
};

# ============================================
# any_* - check if any element matches
# ============================================

subtest 'any_gt - any greater than' => sub {
    ok(any_gt(\@numbers, 10), 'any > 10');
    ok(any_gt(\@numbers, 0), 'any > 0');
    ok(!any_gt(\@numbers, 15), 'none > 15');
    ok(!any_gt(\@numbers, 100), 'none > 100');
};

subtest 'any_lt - any less than' => sub {
    ok(any_lt(\@numbers, 10), 'any < 10');
    ok(any_lt(\@numbers, 100), 'any < 100');
    ok(!any_lt(\@numbers, 1), 'none < 1');
    ok(!any_lt(\@numbers, 0), 'none < 0');
};

subtest 'any_ge - any greater or equal' => sub {
    ok(any_ge(\@numbers, 15), 'any >= 15');
    ok(any_ge(\@numbers, 1), 'any >= 1');
    ok(!any_ge(\@numbers, 16), 'none >= 16');
};

subtest 'any_le - any less or equal' => sub {
    ok(any_le(\@numbers, 1), 'any <= 1');
    ok(any_le(\@numbers, 100), 'any <= 100');
    ok(!any_le(\@numbers, 0), 'none <= 0');
};

subtest 'any_eq - any equal' => sub {
    ok(any_eq(\@numbers, 5), 'any == 5');
    ok(any_eq(\@numbers, 1), 'any == 1');
    ok(!any_eq(\@numbers, 2), 'none == 2');
    ok(!any_eq(\@numbers, 100), 'none == 100');
};

subtest 'any_ne - any not equal' => sub {
    ok(any_ne(\@numbers, 5), 'any != 5');
    ok(any_ne(\@numbers, 100), 'any != 100');
};

# ============================================
# all_* - check if all elements match
# ============================================

subtest 'all_gt - all greater than' => sub {
    ok(all_gt(\@numbers, 0), 'all > 0');
    ok(!all_gt(\@numbers, 1), 'not all > 1');
    ok(!all_gt(\@numbers, 5), 'not all > 5');
};

subtest 'all_lt - all less than' => sub {
    ok(all_lt(\@numbers, 100), 'all < 100');
    ok(all_lt(\@numbers, 16), 'all < 16');
    ok(!all_lt(\@numbers, 15), 'not all < 15');
    ok(!all_lt(\@numbers, 5), 'not all < 5');
};

subtest 'all_ge - all greater or equal' => sub {
    ok(all_ge(\@numbers, 1), 'all >= 1');
    ok(!all_ge(\@numbers, 2), 'not all >= 2');
};

subtest 'all_le - all less or equal' => sub {
    ok(all_le(\@numbers, 15), 'all <= 15');
    ok(!all_le(\@numbers, 14), 'not all <= 14');
};

subtest 'all_eq - all equal' => sub {
    my @same = (5, 5, 5, 5);
    ok(all_eq(\@same, 5), 'all == 5 in same array');
    ok(!all_eq(\@numbers, 5), 'not all == 5 in numbers');
};

subtest 'all_ne - all not equal' => sub {
    ok(all_ne(\@numbers, 100), 'all != 100');
    ok(!all_ne(\@numbers, 5), 'not all != 5');
};

# ============================================
# none_* - check if no elements match
# ============================================

subtest 'none_gt - none greater than' => sub {
    ok(none_gt(\@numbers, 15), 'none > 15');
    ok(none_gt(\@numbers, 100), 'none > 100');
    ok(!none_gt(\@numbers, 10), 'some > 10');
    ok(!none_gt(\@numbers, 0), 'some > 0');
};

subtest 'none_lt - none less than' => sub {
    ok(none_lt(\@numbers, 1), 'none < 1');
    ok(none_lt(\@numbers, 0), 'none < 0');
    ok(!none_lt(\@numbers, 5), 'some < 5');
};

subtest 'none_ge - none greater or equal' => sub {
    ok(none_ge(\@numbers, 16), 'none >= 16');
    ok(!none_ge(\@numbers, 15), 'some >= 15');
};

subtest 'none_le - none less or equal' => sub {
    ok(none_le(\@numbers, 0), 'none <= 0');
    ok(!none_le(\@numbers, 5), 'some <= 5');
};

subtest 'none_eq - none equal' => sub {
    ok(none_eq(\@numbers, 2), 'none == 2');
    ok(none_eq(\@numbers, 100), 'none == 100');
    ok(!none_eq(\@numbers, 5), 'some == 5');
};

subtest 'none_ne - none not equal (all equal)' => sub {
    my @same = (5, 5, 5);
    ok(none_ne(\@same, 5), 'none != 5 (all are 5)');
    ok(!none_ne(\@numbers, 5), 'some != 5');
};

# ============================================
# Edge cases and real-world scenarios
# ============================================

subtest 'empty array edge cases' => sub {
    my @empty = ();

    ok(!defined first_gt(\@empty, 0), 'first_gt empty = undef');
    ok(!defined final_gt(\@empty, 0), 'final_gt empty = undef');
    ok(!any_gt(\@empty, 0), 'any_gt empty = false');
    ok(all_gt(\@empty, 0), 'all_gt empty = true (vacuous)');
    ok(none_gt(\@empty, 0), 'none_gt empty = true');
};

subtest 'single element edge cases' => sub {
    my @single = (5);

    is(first_gt(\@single, 4), 5, 'first_gt single match');
    ok(!defined first_gt(\@single, 5), 'first_gt single no match');

    is(final_lt(\@single, 6), 5, 'final_lt single match');
    ok(all_eq(\@single, 5), 'all_eq single');
    ok(none_eq(\@single, 4), 'none_eq single');
};

subtest 'real-world: threshold filtering' => sub {
    my @temperatures = (18, 22, 25, 28, 31, 35, 29, 24);

    # Find first temperature above 30 (heat warning)
    my $first_hot = first_gt(\@temperatures, 30);
    is($first_hot, 31, 'first temp > 30');

    # Check if any temp exceeds 35 (danger zone)
    ok(!any_gt(\@temperatures, 35), 'no temp > 35');
    ok(any_ge(\@temperatures, 35), 'some temp >= 35');

    # All temps above freezing?
    ok(all_gt(\@temperatures, 0), 'all temps > 0');

    # Find last comfortable temp (<= 25)
    my $last_comfortable = final_le(\@temperatures, 25);
    is($last_comfortable, 24, 'last comfortable temp');
};

subtest 'real-world: version checking' => sub {
    my @versions = (1.0, 1.5, 2.0, 2.5, 3.0);

    # Find first version >= 2.0 (minimum supported)
    my $min_supported = first_ge(\@versions, 2.0);
    is($min_supported, 2.0, 'min supported version');

    # All versions above 0.9?
    ok(all_gt(\@versions, 0.9), 'all versions > 0.9');

    # Any deprecated version (< 1.5)?
    ok(any_lt(\@versions, 1.5), 'some deprecated versions');
};

subtest 'real-world: score analysis' => sub {
    my @scores = (65, 72, 78, 85, 91, 88, 76);

    # Using any/all for pass/fail analysis
    ok(any_ge(\@scores, 90), 'someone got an A');
    ok(!all_ge(\@scores, 70), 'not everyone passed');
    ok(any_lt(\@scores, 70), 'someone failed');

    # Find the first failing score
    my $first_fail = first_lt(\@scores, 70);
    is($first_fail, 65, 'first failing score');
};

subtest 'combined conditions' => sub {
    my @data = (5, 10, 15, 20, 25, 30);

    # Find values in range (10 <= x <= 25)
    my $in_range_start = first_ge(\@data, 10);
    is($in_range_start, 10, 'range start');

    # Values in range using grep
    my @in_range = grep { $_ >= 10 && $_ <= 25 } @data;
    is_deeply(\@in_range, [10, 15, 20, 25], 'values in range');
};

done_testing();
