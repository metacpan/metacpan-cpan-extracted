#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use Func::Util;

# Test built-in callback predicates
my @nums = (-3, -1, 0, 1, 2, 3, 5);
my @refs = ([], {}, sub {}, \1, 'string', undef);
my @mixed = (0, '', undef, 1, 'hello', []);

# ======================
# any_cb tests
# ======================
ok(Func::Util::any_cb(\@nums, ':is_positive'), 'any_cb :is_positive - found');
ok(Func::Util::any_cb(\@nums, ':is_negative'), 'any_cb :is_negative - found');
ok(Func::Util::any_cb(\@nums, ':is_zero'), 'any_cb :is_zero - found');
ok(!Func::Util::any_cb([1, 2, 3], ':is_negative'), 'any_cb :is_negative - none');
ok(!Func::Util::any_cb([], ':is_positive'), 'any_cb empty list returns false');

# ======================
# all_cb tests
# ======================
ok(Func::Util::all_cb([1, 2, 3, 5], ':is_positive'), 'all_cb :is_positive - all match');
ok(!Func::Util::all_cb(\@nums, ':is_positive'), 'all_cb :is_positive - not all');
ok(Func::Util::all_cb([], ':is_positive'), 'all_cb empty list returns true (vacuous)');
ok(Func::Util::all_cb([2, 4, 6, 8], ':is_even'), 'all_cb :is_even');
ok(!Func::Util::all_cb([1, 2, 4, 6], ':is_even'), 'all_cb :is_even - not all');

# ======================
# none_cb tests
# ======================
ok(Func::Util::none_cb([1, 2, 3], ':is_negative'), 'none_cb :is_negative - none match');
ok(!Func::Util::none_cb(\@nums, ':is_negative'), 'none_cb :is_negative - some match');
ok(Func::Util::none_cb([], ':is_positive'), 'none_cb empty list returns true');

# ======================
# first_cb tests
# ======================
is(Func::Util::first_cb(\@nums, ':is_positive'), 1, 'first_cb :is_positive returns 1');
is(Func::Util::first_cb(\@nums, ':is_negative'), -3, 'first_cb :is_negative returns -3');
is(Func::Util::first_cb(\@nums, ':is_zero'), 0, 'first_cb :is_zero returns 0');
is(Func::Util::first_cb([1, 2, 3], ':is_negative'), undef, 'first_cb no match returns undef');

# ======================
# grep_cb tests
# ======================
is_deeply([Func::Util::grep_cb(\@nums, ':is_positive')], [1, 2, 3, 5], 'grep_cb :is_positive');
is_deeply([Func::Util::grep_cb(\@nums, ':is_negative')], [-3, -1], 'grep_cb :is_negative');
is_deeply([Func::Util::grep_cb(\@nums, ':is_even')], [0, 2], 'grep_cb :is_even');
is_deeply([Func::Util::grep_cb(\@nums, ':is_odd')], [-3, -1, 1, 3, 5], 'grep_cb :is_odd');
is_deeply([Func::Util::grep_cb([], ':is_positive')], [], 'grep_cb empty list');

# ======================
# count_cb tests
# ======================
is(Func::Util::count_cb(\@nums, ':is_positive'), 4, 'count_cb :is_positive = 4');
is(Func::Util::count_cb(\@nums, ':is_negative'), 2, 'count_cb :is_negative = 2');
is(Func::Util::count_cb(\@nums, ':is_zero'), 1, 'count_cb :is_zero = 1');
is(Func::Util::count_cb(\@nums, ':is_even'), 2, 'count_cb :is_even = 2');
is(Func::Util::count_cb([], ':is_positive'), 0, 'count_cb empty list = 0');

# ======================
# Type predicate callbacks
# ======================
ok(Func::Util::any_cb(\@refs, ':is_array'), 'any_cb :is_array');
ok(Func::Util::any_cb(\@refs, ':is_hash'), 'any_cb :is_hash');
ok(Func::Util::any_cb(\@refs, ':is_code'), 'any_cb :is_code');
ok(Func::Util::any_cb(\@refs, ':is_ref'), 'any_cb :is_ref');

is(Func::Util::count_cb(\@refs, ':is_array'), 1, 'count_cb :is_array = 1');
is(Func::Util::count_cb(\@refs, ':is_hash'), 1, 'count_cb :is_hash = 1');
is(Func::Util::count_cb(\@refs, ':is_code'), 1, 'count_cb :is_code = 1');
is(Func::Util::count_cb(\@refs, ':is_ref'), 4, 'count_cb :is_ref = 4');

# ======================
# Boolean predicates
# ======================
is(Func::Util::count_cb(\@mixed, ':is_true'), 3, 'count_cb :is_true = 3');
is(Func::Util::count_cb(\@mixed, ':is_false'), 3, 'count_cb :is_false = 3');
is(Func::Util::count_cb(\@mixed, ':is_defined'), 5, 'count_cb :is_defined = 5');

# ======================
# Empty checks
# ======================
my @empties = ('', [], {}, undef, 'x', [1], {a=>1});
is(Func::Util::count_cb(\@empties, ':is_empty'), 4, 'count_cb :is_empty = 4');
is(Func::Util::count_cb(\@empties, ':is_nonempty'), 3, 'count_cb :is_nonempty = 3');

# ======================
# Custom Perl callback registration
# ======================
Func::Util::register_callback('divisible_by_3', sub { $_[0] % 3 == 0 });
ok(Func::Util::has_callback('divisible_by_3'), 'custom callback registered');
is(Func::Util::count_cb([1..10], 'divisible_by_3'), 3, 'custom callback works');
is_deeply([Func::Util::grep_cb([1..10], 'divisible_by_3')], [3, 6, 9], 'grep_cb with custom callback');

# ======================
# list_callbacks
# ======================
my $callbacks = Func::Util::list_callbacks();
ok(ref $callbacks eq 'ARRAY', 'list_callbacks returns arrayref');
ok(grep({ $_ eq ':is_positive' } @$callbacks), 'list_callbacks includes :is_positive');
ok(grep({ $_ eq 'divisible_by_3' } @$callbacks), 'list_callbacks includes custom');

# ======================
# Error handling
# ======================
eval { Func::Util::any_cb(\@nums, 'nonexistent') };
like($@, qr/unknown callback/, 'unknown callback croaks');

eval { Func::Util::any_cb('not_array', ':is_positive') };
like($@, qr/arrayref/, 'non-arrayref croaks');

eval { Func::Util::register_callback(':is_positive', sub {}) };
like($@, qr/already registered/, 'cannot re-register');

done_testing();
