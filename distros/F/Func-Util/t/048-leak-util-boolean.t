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
    is_true is_false bool maybe
);

# Warmup
for (1..10) {
    is_true(1);
    is_false(0);
    bool("test");
    maybe(1, "yes");
}

subtest 'is_true' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = is_true(1);
            my $r2 = is_true(0);
            my $r3 = is_true("");
            my $r4 = is_true("0");
            my $r5 = is_true(undef);
            my $r6 = is_true("hello");
            my $r7 = is_true([1,2,3]);
        }
    } 'is_true does not leak';
};

subtest 'is_false' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = is_false(0);
            my $r2 = is_false("");
            my $r3 = is_false("0");
            my $r4 = is_false(undef);
            my $r5 = is_false(1);
            my $r6 = is_false("hello");
        }
    } 'is_false does not leak';
};

subtest 'bool' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = bool(1);
            my $r2 = bool(0);
            my $r3 = bool("");
            my $r4 = bool("hello");
            my $r5 = bool(undef);
            my $r6 = bool([]);
            my $r7 = bool({});
        }
    } 'bool does not leak';
};

subtest 'maybe' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = maybe(1, "result");
            my $r2 = maybe(undef, "result");
            my $r3 = maybe("defined", "result");
            my $r4 = maybe(0, "result");  # 0 is defined
            my $r5 = maybe("", "result"); # "" is defined
        }
    } 'maybe does not leak';
};

done_testing();
