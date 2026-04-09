#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;


use_ok('Func::Util');
use Func::Util qw(
    is_positive is_negative is_zero
    is_even is_odd is_between
    clamp min2 max2 sign
);

# ============================================
# is_positive
# ============================================

subtest 'is_positive basic' => sub {
    # Positive
    ok(is_positive(1), 'is_positive: 1');
    ok(is_positive(42), 'is_positive: 42');
    ok(is_positive(0.001), 'is_positive: small positive');
    ok(is_positive(1e10), 'is_positive: large');

    # Not positive
    ok(!is_positive(0), 'is_positive: 0');
    ok(!is_positive(-1), 'is_positive: -1');
    ok(!is_positive(-0.001), 'is_positive: small negative');
    ok(!is_positive(undef), 'is_positive: undef');
    ok(!is_positive('hello'), 'is_positive: non-numeric');
};

subtest 'is_positive edge cases' => sub {
    ok(is_positive(0.0000001), 'is_positive: very small');
    ok(is_positive(1e-300), 'is_positive: tiny');
    ok(is_positive(1e100), 'is_positive: huge');

    # Float precision
    ok(!is_positive(-0.0), 'is_positive: -0.0');
};

# ============================================
# is_negative
# ============================================

subtest 'is_negative basic' => sub {
    # Negative
    ok(is_negative(-1), 'is_negative: -1');
    ok(is_negative(-42), 'is_negative: -42');
    ok(is_negative(-0.001), 'is_negative: small negative');
    ok(is_negative(-1e10), 'is_negative: large negative');

    # Not negative
    ok(!is_negative(0), 'is_negative: 0');
    ok(!is_negative(1), 'is_negative: 1');
    ok(!is_negative(0.001), 'is_negative: small positive');
    ok(!is_negative(undef), 'is_negative: undef');
    ok(!is_negative('hello'), 'is_negative: non-numeric');
};

subtest 'is_negative edge cases' => sub {
    ok(is_negative(-0.0000001), 'is_negative: very small');
    ok(is_negative(-1e-300), 'is_negative: tiny');
    ok(is_negative(-1e100), 'is_negative: huge');
};

# ============================================
# is_zero
# ============================================

subtest 'is_zero basic' => sub {
    # Zero
    ok(is_zero(0), 'is_zero: 0');
    ok(is_zero(0.0), 'is_zero: 0.0');
    ok(is_zero(-0), 'is_zero: -0');
    ok(is_zero(-0.0), 'is_zero: -0.0');

    # Not zero
    ok(!is_zero(1), 'is_zero: 1');
    ok(!is_zero(-1), 'is_zero: -1');
    ok(!is_zero(0.001), 'is_zero: small positive');
    ok(!is_zero(-0.001), 'is_zero: small negative');
    ok(!is_zero(undef), 'is_zero: undef');
    ok(!is_zero('hello'), 'is_zero: non-numeric');
};

subtest 'is_zero edge cases' => sub {
    # Very small but not zero
    ok(!is_zero(1e-300), 'is_zero: tiny positive');
    ok(!is_zero(-1e-300), 'is_zero: tiny negative');

    # String zero
    ok(is_zero('0'), 'is_zero: string 0');
    ok(is_zero('0.0'), 'is_zero: string 0.0');
};

# ============================================
# is_even
# ============================================

subtest 'is_even basic' => sub {
    # Even
    ok(is_even(0), 'is_even: 0');
    ok(is_even(2), 'is_even: 2');
    ok(is_even(4), 'is_even: 4');
    ok(is_even(100), 'is_even: 100');
    ok(is_even(-2), 'is_even: -2');
    ok(is_even(-100), 'is_even: -100');

    # Odd
    ok(!is_even(1), 'is_even: 1');
    ok(!is_even(3), 'is_even: 3');
    ok(!is_even(99), 'is_even: 99');
    ok(!is_even(-1), 'is_even: -1');
    ok(!is_even(-99), 'is_even: -99');
};

subtest 'is_even edge cases' => sub {
    # Large numbers
    ok(is_even(1000000), 'is_even: 1000000');
    ok(!is_even(1000001), 'is_even: 1000001');

    # Float that is integer
    ok(is_even(4.0), 'is_even: 4.0');
    ok(!is_even(3.0), 'is_even: 3.0');

    # Non-integers
    ok(!is_even(2.5), 'is_even: 2.5');
    ok(!is_even(undef), 'is_even: undef');
    ok(!is_even('hello'), 'is_even: non-numeric');
};

# ============================================
# is_odd
# ============================================

subtest 'is_odd basic' => sub {
    # Odd
    ok(is_odd(1), 'is_odd: 1');
    ok(is_odd(3), 'is_odd: 3');
    ok(is_odd(99), 'is_odd: 99');
    ok(is_odd(-1), 'is_odd: -1');
    ok(is_odd(-99), 'is_odd: -99');

    # Even
    ok(!is_odd(0), 'is_odd: 0');
    ok(!is_odd(2), 'is_odd: 2');
    ok(!is_odd(100), 'is_odd: 100');
    ok(!is_odd(-2), 'is_odd: -2');
};

subtest 'is_odd edge cases' => sub {
    # Large numbers
    ok(is_odd(1000001), 'is_odd: 1000001');
    ok(!is_odd(1000000), 'is_odd: 1000000');

    # Float that is integer
    ok(is_odd(3.0), 'is_odd: 3.0');
    ok(!is_odd(4.0), 'is_odd: 4.0');

    # Non-integers
    ok(!is_odd(1.5), 'is_odd: 1.5');
    ok(!is_odd(undef), 'is_odd: undef');
};

# ============================================
# is_between (inclusive)
# ============================================

subtest 'is_between basic' => sub {
    # In range
    ok(is_between(5, 0, 10), 'is_between: middle');
    ok(is_between(0, 0, 10), 'is_between: at min');
    ok(is_between(10, 0, 10), 'is_between: at max');
    ok(is_between(5, 5, 5), 'is_between: min == max == val');

    # Out of range
    ok(!is_between(-1, 0, 10), 'is_between: below min');
    ok(!is_between(11, 0, 10), 'is_between: above max');
};

subtest 'is_between edge cases' => sub {
    # Negative range
    ok(is_between(-5, -10, 0), 'is_between: negative range');
    ok(is_between(-10, -10, -5), 'is_between: at negative min');
    ok(is_between(0, -10, 0), 'is_between: at zero max');

    # Floating point
    ok(is_between(0.5, 0, 1), 'is_between: float in range');
    ok(is_between(0.0, 0, 1), 'is_between: 0.0 at min');
    ok(is_between(1.0, 0, 1), 'is_between: 1.0 at max');
    ok(!is_between(1.001, 0, 1), 'is_between: just above max');
    ok(!is_between(-0.001, 0, 1), 'is_between: just below min');

    # Non-numeric
    ok(!is_between(undef, 0, 10), 'is_between: undef value');
    ok(!is_between('hello', 0, 10), 'is_between: non-numeric value');
};

# ============================================
# clamp
# ============================================

subtest 'clamp basic' => sub {
    # In range - unchanged (use scalar() since clamp has no prototype)
    is(scalar(clamp(5, 0, 10)), 5, 'clamp: in range');
    is(scalar(clamp(0, 0, 10)), 0, 'clamp: at min');
    is(scalar(clamp(10, 0, 10)), 10, 'clamp: at max');

    # Below min - clamp to min
    is(scalar(clamp(-5, 0, 10)), 0, 'clamp: below min');
    is(scalar(clamp(-100, 0, 10)), 0, 'clamp: far below min');

    # Above max - clamp to max
    is(scalar(clamp(15, 0, 10)), 10, 'clamp: above max');
    is(scalar(clamp(100, 0, 10)), 10, 'clamp: far above max');
};

subtest 'clamp edge cases' => sub {
    # min == max
    is(scalar(clamp(5, 3, 3)), 3, 'clamp: min == max, value above');
    is(scalar(clamp(1, 3, 3)), 3, 'clamp: min == max, value below');
    is(scalar(clamp(3, 3, 3)), 3, 'clamp: min == max, value equal');

    # Negative range
    is(scalar(clamp(-5, -10, -1)), -5, 'clamp: negative in range');
    is(scalar(clamp(-15, -10, -1)), -10, 'clamp: negative below');
    is(scalar(clamp(0, -10, -1)), -1, 'clamp: negative above');

    # Floating point
    is(scalar(clamp(0.5, 0, 1)), 0.5, 'clamp: float in range');
    is(scalar(clamp(-0.5, 0, 1)), 0, 'clamp: float below');
    is(scalar(clamp(1.5, 0, 1)), 1, 'clamp: float above');
};

# ============================================
# min2
# ============================================

subtest 'min2 basic' => sub {
    is(min2(1, 2), 1, 'min2: 1, 2');
    is(min2(2, 1), 1, 'min2: 2, 1');
    is(min2(5, 5), 5, 'min2: equal');
    is(min2(-1, 1), -1, 'min2: negative');
    is(min2(-5, -3), -5, 'min2: both negative');
};

subtest 'min2 edge cases' => sub {
    is(min2(0, 0), 0, 'min2: both zero');
    is(min2(0, 1), 0, 'min2: zero and positive');
    is(min2(0, -1), -1, 'min2: zero and negative');

    # Float
    is(min2(1.5, 2.5), 1.5, 'min2: floats');
    is(min2(0.001, 0.002), 0.001, 'min2: small floats');

    # Large numbers
    is(min2(1e10, 1e9), 1e9, 'min2: large numbers');
};

# ============================================
# max2
# ============================================

subtest 'max2 basic' => sub {
    is(max2(1, 2), 2, 'max2: 1, 2');
    is(max2(2, 1), 2, 'max2: 2, 1');
    is(max2(5, 5), 5, 'max2: equal');
    is(max2(-1, 1), 1, 'max2: negative and positive');
    is(max2(-5, -3), -3, 'max2: both negative');
};

subtest 'max2 edge cases' => sub {
    is(max2(0, 0), 0, 'max2: both zero');
    is(max2(0, 1), 1, 'max2: zero and positive');
    is(max2(0, -1), 0, 'max2: zero and negative');

    # Float
    is(max2(1.5, 2.5), 2.5, 'max2: floats');
    is(max2(0.001, 0.002), 0.002, 'max2: small floats');

    # Large numbers
    is(max2(1e10, 1e9), 1e10, 'max2: large numbers');
};

# ============================================
# sign
# ============================================

subtest 'sign basic' => sub {
    is(sign(5), 1, 'sign: positive');
    is(sign(100), 1, 'sign: large positive');
    is(sign(0.001), 1, 'sign: small positive');

    is(sign(-5), -1, 'sign: negative');
    is(sign(-100), -1, 'sign: large negative');
    is(sign(-0.001), -1, 'sign: small negative');

    is(sign(0), 0, 'sign: zero');
    is(sign(0.0), 0, 'sign: zero float');
};

subtest 'sign edge cases' => sub {
    # Very small numbers
    is(sign(1e-300), 1, 'sign: tiny positive');
    is(sign(-1e-300), -1, 'sign: tiny negative');

    # Large numbers
    is(sign(1e100), 1, 'sign: huge positive');
    is(sign(-1e100), -1, 'sign: huge negative');

    # Non-numeric
    is(sign(undef), undef, 'sign: undef');
    is(sign('hello'), undef, 'sign: non-numeric string');

    # Numeric strings
    is(sign('42'), 1, 'sign: positive string');
    is(sign('-42'), -1, 'sign: negative string');
    is(sign('0'), 0, 'sign: zero string');
};

# ============================================
# Combined numeric tests
# ============================================

subtest 'numeric function combinations' => sub {
    # Using sign with clamp
    my $val = -15;
    my $clamped = clamp($val, -10, 10);
    is($clamped, -10, 'clamp negative');
    is(sign($clamped), -1, 'sign of clamped');

    # Using is_between with min2/max2
    my $a = 5;
    my $b = 10;
    my $min = min2($a, $b);
    my $max = max2($a, $b);
    ok(is_between(7, $min, $max), 'is_between with min2/max2');
};

subtest 'numeric predicates comprehensive' => sub {
    # Test all predicates on same values
    my @values = (-10, -1, 0, 1, 10);

    for my $v (@values) {
        my $pos = is_positive($v);
        my $neg = is_negative($v);
        my $zer = is_zero($v);

        # Exactly one should be true
        my $count = ($pos ? 1 : 0) + ($neg ? 1 : 0) + ($zer ? 1 : 0);
        is($count, 1, "exactly one of pos/neg/zero for $v");
    }
};

done_testing;
