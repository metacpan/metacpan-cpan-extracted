#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Func::Util qw(firstr);

# Warmup
for (1..10) {
    my $r = firstr(sub { $_ > 3 }, [1, 2, 3, 4, 5]);
}

# ==== firstr - first with arrayref reversed ====

subtest 'firstr' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..500) {
            my $r1 = firstr(sub { $_ > 3 }, $nums);
            my $r2 = firstr(sub { $_ > 10 }, $nums);  # no match
            my $r3 = firstr(sub { $_ < 3 }, $nums);
        }
    } 'firstr does not leak';
};

# ==== Edge cases for previously tested functions ====

subtest 'trim edge cases' => sub {
    use Func::Util qw(trim ltrim rtrim);
    no_leaks_ok {
        for (1..500) {
            my $r1 = trim(undef);           # undef handling
            my $r2 = trim("");              # empty string
            my $r3 = trim("   ");           # only whitespace
            my $r4 = trim("\t\n\r test \t\n\r");  # various whitespace
        }
    } 'trim edge cases do not leak';
};

subtest 'nvl/coalesce edge cases' => sub {
    use Func::Util qw(nvl coalesce);
    no_leaks_ok {
        for (1..500) {
            my $r1 = nvl(0, 42);            # 0 is defined
            my $r2 = nvl("", 42);           # "" is defined
            my $r3 = coalesce(undef, undef, undef);  # all undef
            my $r4 = coalesce(undef, 42);   # first defined wins
        }
    } 'nvl/coalesce edge cases do not leak';
};

subtest 'dig edge cases' => sub {
    use Func::Util qw(dig);
    my $data = { a => { b => [1, 2, { c => 3 }] } };
    no_leaks_ok {
        for (1..500) {
            my $r1 = dig($data, 'a');               # single key
            my $r2 = dig($data, 'a', 'b', 2, 'c');  # mixed hash/array
            my $r3 = dig($data, 'x');               # nonexistent
            my $r4 = dig($data, 'a', 'x', 'y');     # deep nonexistent
        }
    } 'dig edge cases do not leak';
};

subtest 'array functions edge cases' => sub {
    use Func::Util qw(array_len array_first array_last);
    my $empty = [];
    no_leaks_ok {
        for (1..500) {
            my $r1 = array_len($empty);
            my $r2 = array_first($empty);
            my $r3 = array_last($empty);
            my $r4 = array_len(undef);   # undef handling
        }
    } 'array function edge cases do not leak';
};

subtest 'hash functions edge cases' => sub {
    use Func::Util qw(hash_size is_empty_hash);
    my $empty = {};
    no_leaks_ok {
        for (1..500) {
            my $r1 = hash_size($empty);
            my $r2 = is_empty_hash($empty);
            my $r3 = hash_size(undef);   # undef handling
        }
    } 'hash function edge cases do not leak';
};

subtest 'predicate edge cases with undef' => sub {
    use Func::Util qw(is_array is_hash is_code is_ref is_defined);
    no_leaks_ok {
        for (1..500) {
            my $r1 = is_array(undef);
            my $r2 = is_hash(undef);
            my $r3 = is_code(undef);
            my $r4 = is_ref(undef);
            my $r5 = is_defined(undef);
        }
    } 'predicate undef edge cases do not leak';
};

subtest 'numeric edge cases' => sub {
    use Func::Util qw(is_num is_int is_positive is_negative is_zero clamp min2 max2);
    no_leaks_ok {
        for (1..500) {
            # Large numbers
            my $r1 = is_num(1e308);
            my $r2 = is_int(2**31);

            # Floating point
            my $r3 = is_positive(0.0001);
            my $r4 = is_negative(-0.0001);
            my $r5 = is_zero(0.0);

            # Edge clamp
            my $r6 = clamp(-1e308, 0, 100);
            my $r7 = clamp(1e308, 0, 100);

            # Same values
            my $r8 = min2(5, 5);
            my $r9 = max2(5, 5);
        }
    } 'numeric edge cases do not leak';
};

subtest 'string function edge cases' => sub {
    use Func::Util qw(starts_with ends_with replace_all is_empty);
    no_leaks_ok {
        for (1..500) {
            # Empty strings
            my $r1 = starts_with("", "x");
            my $r2 = ends_with("", "x");
            my $r3 = starts_with("test", "");
            my $r4 = ends_with("test", "");

            # Undef handling
            my $r5 = starts_with(undef, "x");
            my $r6 = ends_with(undef, "x");

            # Replace with empty
            my $r7 = replace_all("hello", "l", "");
            my $r8 = replace_all("", "x", "y");

            # is_empty variations
            my $r9 = is_empty(0);      # 0 is not empty
            my $r10 = is_empty("0");   # "0" is not empty
        }
    } 'string function edge cases do not leak';
};

subtest 'callback functions with empty arrays' => sub {
    use Func::Util qw(first any all none count);
    my $empty = [];
    no_leaks_ok {
        for (1..500) {
            my $r1 = first(sub { 1 }, $empty);
            my $r2 = any(sub { 1 }, $empty);
            my $r3 = all(sub { 1 }, $empty);   # true for empty (vacuous truth)
            my $r4 = none(sub { 1 }, $empty);  # true for empty
            my $r5 = count(sub { 1 }, $empty);
        }
    } 'callback functions with empty arrays do not leak';
};

done_testing();
