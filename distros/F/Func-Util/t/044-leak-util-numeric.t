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
    is_num is_int is_even is_odd
    is_positive is_negative is_zero is_between
    clamp min2 max2 sign
);

# Warmup
for (1..10) {
    is_num(42);
    clamp(5, 0, 10);
}

subtest 'is_num' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_num(42);
            my $r2 = is_num(3.14);
            my $r3 = is_num("hello");
            my $r4 = is_num(undef);
        }
    } 'is_num does not leak';
};

subtest 'is_int' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_int(42);
            my $r2 = is_int(3.14);
            my $r3 = is_int(-5);
        }
    } 'is_int does not leak';
};

subtest 'is_even and is_odd' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_even(4);
            my $r2 = is_even(5);
            my $r3 = is_odd(5);
            my $r4 = is_odd(4);
        }
    } 'is_even/is_odd do not leak';
};

subtest 'is_positive/negative/zero' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_positive(5);
            my $r2 = is_negative(-5);
            my $r3 = is_zero(0);
            my $r4 = is_positive(-1);
        }
    } 'is_positive/negative/zero do not leak';
};

subtest 'is_between' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = is_between(5, 0, 10);
            my $r2 = is_between(-5, 0, 10);
            my $r3 = is_between(15, 0, 10);
            my $r4 = is_between(0, 0, 10);
            my $r5 = is_between(10, 0, 10);
        }
    } 'is_between does not leak';
};

subtest 'clamp' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = clamp(5, 0, 10);
            my $r2 = clamp(-5, 0, 10);
            my $r3 = clamp(15, 0, 10);
        }
    } 'clamp does not leak';
};

subtest 'min2 and max2' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = min2(5, 10);
            my $r2 = max2(5, 10);
            my $r3 = min2(-1, 1);
            my $r4 = max2(-1, 1);
        }
    } 'min2/max2 do not leak';
};

subtest 'sign' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = sign(5);
            my $r2 = sign(-5);
            my $r3 = sign(0);
        }
    } 'sign does not leak';
};

done_testing();
