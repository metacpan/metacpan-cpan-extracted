#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Func::Util qw(
    list_callbacks has_callback register_callback
    is_between clamp sign maybe
    stub_true stub_false stub_array stub_hash stub_string stub_zero
    force lazy memo
);

# first_inline requires MULTICALL API (Perl 5.11+)
my $has_first_inline = $] >= 5.011 && Func::Util->can('first_inline');
if ($has_first_inline) {
    Func::Util->import('first_inline');
}

# ============================================
# Edge Cases and Low-Coverage Functions
# ============================================

SKIP: {
    skip "first_inline requires Perl 5.11+ (MULTICALL)", 1 unless $has_first_inline;

    subtest 'first_inline - optimized first with inlined block' => sub {
        # first_inline works like first but inlines pure Perl subs
        my @numbers = (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);

        my $found = first_inline(sub { $_ > 5 }, @numbers);
        is($found, 6, 'first_inline finds first > 5');

        $found = first_inline(sub { $_ % 2 == 0 }, @numbers);
        is($found, 2, 'first_inline finds first even');

        $found = first_inline(sub { $_ > 100 }, @numbers);
        ok(!defined $found, 'first_inline returns undef when no match');

        # Empty list
        $found = first_inline(sub { 1 });
        ok(!defined $found, 'first_inline on empty list returns undef');

        # Complex condition
        my @data = ({ val => 1 }, { val => 5 }, { val => 10 });
        $found = first_inline(sub { $_->{val} > 3 }, @data);
        is_deeply($found, { val => 5 }, 'first_inline with complex condition');
    };
}

subtest 'callback registry - list and management' => sub {
    # List all built-in callbacks
    my $callbacks = list_callbacks();
    ok(ref $callbacks eq 'ARRAY', 'list_callbacks returns arrayref');

    # Check for standard built-in callbacks
    my %cb_set = map { $_ => 1 } @$callbacks;
    ok($cb_set{':is_positive'}, 'has :is_positive');
    ok($cb_set{':is_negative'}, 'has :is_negative');
    ok($cb_set{':is_zero'}, 'has :is_zero');
    ok($cb_set{':is_even'}, 'has :is_even');
    ok($cb_set{':is_odd'}, 'has :is_odd');
    ok($cb_set{':is_defined'}, 'has :is_defined');
    ok($cb_set{':is_true'}, 'has :is_true');
    ok($cb_set{':is_false'}, 'has :is_false');
    ok($cb_set{':is_ref'}, 'has :is_ref');
    ok($cb_set{':is_array'}, 'has :is_array');
    ok($cb_set{':is_hash'}, 'has :is_hash');
    ok($cb_set{':is_code'}, 'has :is_code');

    # has_callback for built-ins
    ok(has_callback(':is_positive'), 'has_callback :is_positive');
    ok(has_callback(':is_number'), 'has_callback :is_number');
    ok(!has_callback('nonexistent_xyz_123'), 'has_callback returns false for unknown');

    # Register custom callback
    register_callback('test_custom_64', sub { $_[0] > 64 });
    ok(has_callback('test_custom_64'), 'custom callback registered');

    # Verify it appears in list
    my $new_list = list_callbacks();
    my %new_set = map { $_ => 1 } @$new_list;
    ok($new_set{'test_custom_64'}, 'custom callback in list');
};

subtest 'is_between - range checking' => sub {
    # Basic range checks
    ok(is_between(5, 1, 10), '5 is between 1 and 10');
    ok(is_between(1, 1, 10), '1 is between 1 and 10 (inclusive)');
    ok(is_between(10, 1, 10), '10 is between 1 and 10 (inclusive)');
    ok(!is_between(0, 1, 10), '0 is not between 1 and 10');
    ok(!is_between(11, 1, 10), '11 is not between 1 and 10');

    # Negative ranges
    ok(is_between(-5, -10, 0), '-5 is between -10 and 0');
    ok(is_between(0, -10, 10), '0 is between -10 and 10');

    # Float ranges
    ok(is_between(3.14, 3, 4), '3.14 is between 3 and 4');
    ok(is_between(0.5, 0, 1), '0.5 is between 0 and 1');

    # Edge: same min and max
    ok(is_between(5, 5, 5), '5 is between 5 and 5');
    ok(!is_between(4, 5, 5), '4 is not between 5 and 5');
};

subtest 'stubs - constant value generators' => sub {
    # stub_true always returns true (1)
    is(stub_true(), 1, 'stub_true returns 1');
    is(stub_true("ignored"), 1, 'stub_true ignores args');

    # stub_false always returns false (empty string)
    is(stub_false(), '', 'stub_false returns empty string');
    is(stub_false(1, 2, 3), '', 'stub_false ignores args');

    # stub_array returns empty array
    my @arr = stub_array();
    is_deeply(\@arr, [], 'stub_array returns empty array');

    # stub_hash returns empty hash
    my %hash = stub_hash();
    is_deeply(\%hash, {}, 'stub_hash returns empty hash');

    # stub_string returns empty string
    is(stub_string(), '', 'stub_string returns empty string');

    # stub_zero returns 0
    is(stub_zero(), 0, 'stub_zero returns 0');
    ok(stub_zero() == 0, 'stub_zero is numerically 0');
};

subtest 'sign - extract sign of number' => sub {
    is(sign(42), 1, 'sign of positive is 1');
    is(sign(-42), -1, 'sign of negative is -1');
    is(sign(0), 0, 'sign of zero is 0');

    is(sign(0.001), 1, 'sign of small positive is 1');
    is(sign(-0.001), -1, 'sign of small negative is -1');

    is(sign(1e100), 1, 'sign of large positive is 1');
    is(sign(-1e100), -1, 'sign of large negative is -1');
};

subtest 'maybe - conditional value' => sub {
    # maybe returns $then if $val is DEFINED, undef otherwise
    # Usage: maybe($val, $then) -> $then if defined($val), else undef
    is(maybe(1, 42), 42, 'maybe with defined value');
    is(maybe(0, 42), 42, 'maybe with defined zero');
    is(maybe("yes", "value"), "value", 'maybe with defined string');
    is(maybe("", "value"), "value", 'maybe with defined empty string');
    is(maybe(undef, 42), undef, 'maybe with undef returns undef');

    # Useful for optional hash values
    my $has_name = "Alice";
    my $no_age = undef;
    my %opts = (
        name => maybe($has_name, $has_name),
        age  => maybe($no_age, 30),
    );
    is($opts{name}, "Alice", 'maybe for defined name');
    ok(!defined $opts{age}, 'maybe excludes undef age');
};

subtest 'clamp edge cases' => sub {
    # Already tested but adding edge cases
    is(clamp(50, 0, 100), 50, 'clamp: value in range');
    is(clamp(-10, 0, 100), 0, 'clamp: below min');
    is(clamp(150, 0, 100), 100, 'clamp: above max');

    # Edge: value equals boundary
    is(clamp(0, 0, 100), 0, 'clamp: value equals min');
    is(clamp(100, 0, 100), 100, 'clamp: value equals max');

    # Negative range
    is(clamp(-50, -100, -10), -50, 'clamp: negative range, in bounds');
    is(clamp(0, -100, -10), -10, 'clamp: negative range, above');
    is(clamp(-200, -100, -10), -100, 'clamp: negative range, below');

    # Float values
    is(clamp(3.14, 0, 10), 3.14, 'clamp: float in range');
    is(clamp(3.14, 0, 3), 3, 'clamp: float above max');
};

subtest 'lazy/force - deferred evaluation' => sub {
    my $computed = 0;

    my $lazy_val = lazy(sub {
        $computed++;
        return 42;
    });

    is($computed, 0, 'lazy: not computed yet');

    my $result = force($lazy_val);
    is($computed, 1, 'lazy: computed after force');
    is($result, 42, 'lazy: correct value');

    # Multiple force calls don't re-evaluate
    force($lazy_val);
    force($lazy_val);
    is($computed, 1, 'lazy: still only computed once');

    # Lazy with complex computation
    my $lazy_list = lazy(sub { [1, 2, 3, 4, 5] });
    my $list = force($lazy_list);
    is_deeply($list, [1, 2, 3, 4, 5], 'lazy: complex value');
};

subtest 'memo - memoization edge cases' => sub {
    my $calls = 0;

    my $memoized = memo(sub {
        $calls++;
        return $_[0] * 2;
    });

    is($memoized->(5), 10, 'memo: first call');
    is($calls, 1, 'memo: called once');

    is($memoized->(5), 10, 'memo: cached call');
    is($calls, 1, 'memo: still called once');

    is($memoized->(10), 20, 'memo: different arg');
    is($calls, 2, 'memo: called again for new arg');

    # String keys
    my $str_memo = memo(sub { uc($_[0]) });
    is($str_memo->("hello"), "HELLO", 'memo: string arg');
    is($str_memo->("hello"), "HELLO", 'memo: string cached');

    # Undef handling
    my $undef_memo = memo(sub { defined $_[0] ? $_[0] : "default" });
    is($undef_memo->(undef), "default", 'memo: undef arg');
    is($undef_memo->(undef), "default", 'memo: undef cached');
};

subtest 'real-world: configuration validation' => sub {
    my $config = {
        port => 8080,
        timeout => 30,
        retries => 5,
        debug => 1,
    };

    # Validate port in range
    ok(is_between($config->{port}, 1, 65535), 'port in valid range');

    # Clamp timeout to safe range
    my $safe_timeout = clamp($config->{timeout}, 5, 120);
    is($safe_timeout, 30, 'timeout in safe range');

    # Use maybe for optional debug
    my $debug_level = maybe($config->{debug}, 3);
    is($debug_level, 3, 'debug level set');

    # Sign for direction indicators
    my $trend = -15;
    is(sign($trend), -1, 'negative trend indicator');
};

subtest 'real-world: data pipeline with stubs' => sub {
    # Use stubs as default callbacks
    my $on_success = stub_true();   # Always succeeds
    my $on_error = stub_false();    # Always fails

    # Simulate processing
    my @results;
    for my $item (1, 2, 3) {
        if ($on_success) {
            push @results, $item * 2;
        }
    }
    is_deeply(\@results, [2, 4, 6], 'stubs in pipeline');

    # Empty defaults
    my @default_array = stub_array();
    my %default_hash = stub_hash();
    push @default_array, 1, 2, 3;
    $default_hash{key} = 'value';

    is(scalar(@default_array), 3, 'stub_array is mutable');
    is($default_hash{key}, 'value', 'stub_hash is mutable');
};

done_testing();
