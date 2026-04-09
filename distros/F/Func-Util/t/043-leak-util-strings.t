#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Func::Util qw(
    trim ltrim rtrim
    starts_with ends_with
    is_empty is_string
    replace_all
);

# Warmup
for (1..10) {
    trim("  test  ");
}

subtest 'trim' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = trim("  hello world  ");
            my $r2 = trim("no spaces");
            my $r3 = trim("");
        }
    } 'trim does not leak';
};

subtest 'ltrim' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = ltrim("  hello");
            my $r2 = ltrim("hello  ");
        }
    } 'ltrim does not leak';
};

subtest 'rtrim' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = rtrim("hello  ");
            my $r2 = rtrim("  hello");
        }
    } 'rtrim does not leak';
};

subtest 'starts_with' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = starts_with("hello world", "hello");
            my $r2 = starts_with("hello world", "world");
            my $r3 = starts_with("", "x");
        }
    } 'starts_with does not leak';
};

subtest 'ends_with' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = ends_with("hello world", "world");
            my $r2 = ends_with("hello world", "hello");
            my $r3 = ends_with("", "x");
        }
    } 'ends_with does not leak';
};

subtest 'is_empty' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_empty("");
            my $r2 = is_empty("hello");
            my $r3 = is_empty(undef);
        }
    } 'is_empty does not leak';
};

subtest 'is_string' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_string("hello");
            my $r2 = is_string(42);
            my $r3 = is_string([]);
            my $r4 = is_string(undef);
        }
    } 'is_string does not leak';
};

subtest 'replace_all' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r = replace_all("hello world hello", "hello", "hi");
            my $r2 = replace_all("aaa", "a", "bb");
            my $r3 = replace_all("no match", "xyz", "abc");
        }
    } 'replace_all does not leak';
};

done_testing();
