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
    identity always noop
    stub_true stub_false stub_array stub_hash stub_string stub_zero
    first any all none
    count negate once
);

# Warmup
for (1..10) {
    identity(42);
    any(sub { $_ > 3 }, [1,2,3,4,5]);
}

subtest 'identity' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = identity(42);
            my $r2 = identity("string");
            my $r3 = identity([1,2,3]);
        }
    } 'identity does not leak';
};

subtest 'always' => sub {
    my $fn = always(42);
    no_leaks_ok {
        for (1..1000) {
            my $r = $fn->();
            my $r2 = $fn->(1, 2, 3);
        }
    } 'always does not leak';
};

subtest 'noop' => sub {
    no_leaks_ok {
        for (1..1000) {
            noop();
            noop(1, 2, 3);
        }
    } 'noop does not leak';
};

subtest 'stub functions' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = stub_true();
            my $r2 = stub_false();
            my $r3 = stub_array();
            my $r4 = stub_hash();
            my $r5 = stub_string();
            my $r6 = stub_zero();
        }
    } 'stub functions do not leak';
};

subtest 'first' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..500) {
            my $r = first(sub { $_ > 3 }, $nums);
            my $r2 = first(sub { $_ > 10 }, $nums);
        }
    } 'first does not leak';
};

subtest 'any' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..500) {
            my $r = any(sub { $_ > 3 }, $nums);
            my $r2 = any(sub { $_ > 10 }, $nums);
        }
    } 'any does not leak';
};

subtest 'all' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..500) {
            my $r = all(sub { $_ > 0 }, $nums);
            my $r2 = all(sub { $_ > 3 }, $nums);
        }
    } 'all does not leak';
};

subtest 'none' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..500) {
            my $r = none(sub { $_ > 10 }, $nums);
            my $r2 = none(sub { $_ > 3 }, $nums);
        }
    } 'none does not leak';
};

subtest 'count' => sub {
    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    no_leaks_ok {
        for (1..500) {
            my $r = count(sub { $_ % 2 == 0 }, $nums);
        }
    } 'count does not leak';
};

subtest 'negate' => sub {
    my $is_even = sub { $_[0] % 2 == 0 };
    no_leaks_ok {
        for (1..500) {
            my $is_odd = negate($is_even);
            my $r = $is_odd->(3);
            my $r2 = $is_odd->(4);
        }
    } 'negate does not leak';
};

subtest 'once' => sub {
    no_leaks_ok {
        for (1..500) {
            my $counter = 0;
            my $fn = once(sub { $counter++ });
            $fn->();
            $fn->();
            $fn->();
        }
    } 'once does not leak';
};

done_testing();
