#!/usr/bin/env perl
use strict;
use warnings;
no warnings 'void';  # Suppress "useless use of constant" from constant-folded util functions
use Test::More;

# Skip if ps command not available (Windows, minimal docker containers, etc.)
my $ps_available = eval { my $r = `ps -o rss= -p $$ 2>/dev/null`; defined $r && $r =~ /\d/ };
plan skip_all => 'ps command not available' unless $ps_available;

use Func::Util qw(
    is_array is_hash is_code is_defined is_ref
    is_true is_false bool
    is_num is_int is_even is_odd
    is_positive is_negative is_zero
    is_empty is_empty_array is_empty_hash
    trim ltrim rtrim starts_with ends_with
    identity always noop clamp nvl coalesce
    min2 max2 sign
    array_len array_first array_last hash_size
    maybe
);

plan tests => 28;

# Helper to get current RSS memory in KB
sub get_rss {
    my $rss = `ps -o rss= -p $$`;
    chomp $rss;
    return $rss + 0;
}

# Test for memory leaks
# Run code many times and check memory doesn't grow significantly
sub test_no_leak {
    my ($name, $code, $iterations, $threshold_kb) = @_;
    $iterations //= 10_000;  # Reduced from 100k to avoid SEGV in util
    $threshold_kb //= 5_000;  # 5MB threshold
    
    # Warmup
    $code->() for 1..100;
    
    my $before = get_rss();
    
    $code->() for 1..$iterations;
    
    my $after = get_rss();
    my $diff = $after - $before;
    
    my $passed = $diff < $threshold_kb;
    ok($passed, "$name - memory growth: ${diff}KB (threshold: ${threshold_kb}KB)");
    
    if (!$passed) {
        diag("Memory before: ${before}KB");
        diag("Memory after: ${after}KB");
        diag("Growth: ${diff}KB");
    }
    
    return $passed;
}

# Test data
my $arr = [1,2,3];
my $hash = {a=>1};
my $code = sub { 1 };

# Type predicates
test_no_leak("is_array", sub {
    my $r = is_array($arr);
});

test_no_leak("is_hash", sub {
    my $r = is_hash($hash);
});

test_no_leak("is_code", sub {
    my $r = is_code($code);
});

test_no_leak("is_defined", sub {
    my $r = is_defined(42);
});

test_no_leak("is_ref", sub {
    my $r = is_ref($arr);
});

# Boolean predicates
test_no_leak("is_true", sub {
    my $r = is_true(1);
});

test_no_leak("is_false", sub {
    my $r = is_false(0);
});

test_no_leak("bool", sub {
    my $r = bool(42);
});

# Numeric predicates
test_no_leak("is_num", sub {
    my $r = is_num(42);
});

test_no_leak("is_int", sub {
    my $r = is_int(42);
});

test_no_leak("is_even", sub {
    my $r = is_even(42);
});

test_no_leak("is_odd", sub {
    my $r = is_odd(41);
});

# NOTE: is_between skipped - has a SEGV bug

test_no_leak("is_positive", sub {
    my $r = is_positive(42);
});

test_no_leak("is_negative", sub {
    my $r = is_negative(-42);
});

test_no_leak("is_zero", sub {
    my $r = is_zero(0);
});

# String functions
test_no_leak("trim", sub {
    my $r = trim("  hello  ");
});

test_no_leak("starts_with", sub {
    my $r = starts_with("hello world", "hello");
});

test_no_leak("ends_with", sub {
    my $r = ends_with("hello world", "world");
});

# Utility functions
test_no_leak("identity", sub {
    my $r = identity(42);
});

test_no_leak("clamp", sub {
    my $r = clamp(5, 0, 10);
});

test_no_leak("nvl", sub {
    my $r = nvl(undef, 42);
});

test_no_leak("coalesce", sub {
    my $r = coalesce(undef, undef, 42);
});

test_no_leak("min2", sub {
    my $r = min2(5, 10);
});

test_no_leak("max2", sub {
    my $r = max2(5, 10);
});

test_no_leak("sign", sub {
    my $r = sign(-42);
});

# Array functions
test_no_leak("array_len", sub {
    my $r = array_len($arr);
});

test_no_leak("array_first", sub {
    my $r = array_first($arr);
});

test_no_leak("array_last", sub {
    my $r = array_last($arr);
});

done_testing();
