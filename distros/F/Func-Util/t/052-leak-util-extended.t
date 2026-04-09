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
    pick pluck omit defaults
    partition uniq
    bool
    is_even is_odd is_between
    sign
);

# Warmup
for (1..10) {
    pick({ a => 1, b => 2, c => 3 }, qw(a b));
    uniq([1, 2, 2, 3, 3, 3]);
}

# ============================================
# Object manipulation
# ============================================

subtest 'pick no leak' => sub {
    my $obj = { a => 1, b => 2, c => 3, d => 4, e => 5 };
    no_leaks_ok {
        for (1..200) {
            my $r1 = pick($obj, qw(a b));
            my $r2 = pick($obj, qw(c d e));
            my $r3 = pick($obj, qw(nonexistent));
        }
    } 'pick does not leak';
};

subtest 'omit no leak' => sub {
    my $obj = { a => 1, b => 2, c => 3, d => 4, e => 5 };
    no_leaks_ok {
        for (1..200) {
            my $r1 = omit($obj, qw(a b));
            my $r2 = omit($obj, qw(c d e));
            my $r3 = omit($obj, qw(nonexistent));
        }
    } 'omit does not leak';
};

subtest 'pluck no leak' => sub {
    my $items = [
        { name => 'a', val => 1 },
        { name => 'b', val => 2 },
        { name => 'c', val => 3 },
    ];
    no_leaks_ok {
        for (1..200) {
            my $r1 = pluck($items, 'name');
            my $r2 = pluck($items, 'val');
            my $r3 = pluck($items, 'nonexistent');
        }
    } 'pluck does not leak';
};

subtest 'defaults no leak' => sub {
    my $target = { a => 1 };
    my $source = { a => 10, b => 2, c => 3 };
    no_leaks_ok {
        for (1..200) {
            my $r = defaults($target, $source);
        }
    } 'defaults does not leak';
};

# ============================================
# Array operations
# ============================================

subtest 'partition no leak' => sub {
    my $nums = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    no_leaks_ok {
        for (1..200) {
            my ($evens, $odds) = partition(sub { $_ % 2 == 0 }, $nums);
        }
    } 'partition does not leak';
};

subtest 'uniq no leak' => sub {
    my $nums = [1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 5];
    no_leaks_ok {
        for (1..200) {
            my $r = uniq($nums);
        }
    } 'uniq does not leak';
};

subtest 'uniq with strings no leak' => sub {
    my $strs = [qw(apple banana apple cherry banana apple)];
    no_leaks_ok {
        for (1..200) {
            my $r = uniq($strs);
        }
    } 'uniq with strings does not leak';
};


# ============================================
# Boolean conversion
# ============================================

subtest 'bool no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = bool(1);
            my $r2 = bool(0);
            my $r3 = bool("true");
            my $r4 = bool("");
            my $r5 = bool(undef);
            my $r6 = bool([1, 2, 3]);
        }
    } 'bool does not leak';
};

# ============================================
# Numeric predicates
# ============================================

subtest 'is_even/is_odd no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = is_even(2);
            my $r2 = is_even(3);
            my $r3 = is_odd(2);
            my $r4 = is_odd(3);
            my $r5 = is_even(0);
            my $r6 = is_odd(0);
            my $r7 = is_even(-4);
            my $r8 = is_odd(-3);
        }
    } 'is_even/is_odd does not leak';
};

subtest 'is_between no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = is_between(5, 1, 10);
            my $r2 = is_between(0, 1, 10);
            my $r3 = is_between(15, 1, 10);
            my $r4 = is_between(1, 1, 10);   # boundary
            my $r5 = is_between(10, 1, 10);  # boundary
        }
    } 'is_between does not leak';
};

subtest 'sign no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = sign(42);
            my $r2 = sign(-42);
            my $r3 = sign(0);
            my $r4 = sign(0.1);
            my $r5 = sign(-0.1);
        }
    } 'sign does not leak';
};

# ============================================
# Edge cases
# ============================================

subtest 'pick with empty result no leak' => sub {
    my $obj = { a => 1 };
    no_leaks_ok {
        for (1..200) {
            my $r = pick($obj, qw(x y z));
        }
    } 'pick with empty result does not leak';
};

subtest 'omit all keys no leak' => sub {
    my $obj = { a => 1, b => 2 };
    no_leaks_ok {
        for (1..200) {
            my $r = omit($obj, qw(a b));
        }
    } 'omit all keys does not leak';
};

subtest 'partition all match no leak' => sub {
    my $nums = [2, 4, 6, 8, 10];
    no_leaks_ok {
        for (1..200) {
            my ($matched, $unmatched) = partition(sub { $_ % 2 == 0 }, $nums);
        }
    } 'partition all match does not leak';
};

subtest 'partition none match no leak' => sub {
    my $nums = [1, 3, 5, 7, 9];
    no_leaks_ok {
        for (1..200) {
            my ($matched, $unmatched) = partition(sub { $_ % 2 == 0 }, $nums);
        }
    } 'partition none match does not leak';
};

subtest 'uniq already unique no leak' => sub {
    my $nums = [1, 2, 3, 4, 5];
    no_leaks_ok {
        for (1..200) {
            my $r = uniq($nums);
        }
    } 'uniq already unique does not leak';
};

subtest 'uniq empty no leak' => sub {
    my $empty = [];
    no_leaks_ok {
        for (1..200) {
            my $r = uniq($empty);
        }
    } 'uniq empty does not leak';
};

done_testing();
