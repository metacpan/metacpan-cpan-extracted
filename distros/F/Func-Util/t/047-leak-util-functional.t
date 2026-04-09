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
    dig tap pipeline compose partial
    nvl coalesce
    memo lazy force
);

# Warmup
for (1..10) {
    dig({a => {b => 1}}, 'a', 'b');
    nvl(undef, 42);
}

subtest 'dig' => sub {
    my $data = {
        a => {
            b => {
                c => 42
            }
        }
    };
    no_leaks_ok {
        for (1..500) {
            my $r = dig($data, 'a', 'b', 'c');
            my $r2 = dig($data, 'a', 'b');
            my $r3 = dig($data, 'x', 'y');  # nonexistent
        }
    } 'dig does not leak';
};

subtest 'dig with arrays' => sub {
    my $data = {
        items => [
            { name => 'first' },
            { name => 'second' },
        ]
    };
    no_leaks_ok {
        for (1..500) {
            my $r = dig($data, 'items', 0, 'name');
            my $r2 = dig($data, 'items', 1, 'name');
        }
    } 'dig with arrays does not leak';
};

subtest 'tap' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r = tap(sub { my $x = shift }, 42);
            my $r2 = tap(sub { }, "hello");
        }
    } 'tap does not leak';
};

subtest 'pipeline' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r = pipeline(5,
                sub { $_[0] * 2 },
                sub { $_[0] + 1 },
                sub { $_[0] * 3 }
            );
        }
    } 'pipeline does not leak';
};

subtest 'compose' => sub {
    no_leaks_ok {
        for (1..500) {
            my $fn = compose(
                sub { $_[0] * 3 },
                sub { $_[0] + 1 },
                sub { $_[0] * 2 }
            );
            my $r = $fn->(5);
        }
    } 'compose does not leak';
};

subtest 'partial' => sub {
    my $add = sub { $_[0] + $_[1] };
    no_leaks_ok {
        for (1..500) {
            my $add5 = partial($add, 5);
            my $r = $add5->(3);
            my $r2 = $add5->(10);
        }
    } 'partial does not leak';
};

subtest 'nvl' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = nvl(undef, 42);
            my $r2 = nvl(0, 42);
            my $r3 = nvl("", 42);
            my $r4 = nvl("value", 42);
        }
    } 'nvl does not leak';
};

subtest 'coalesce' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r = coalesce(undef, undef, 42);
            my $r2 = coalesce(0, 1, 2);
            my $r3 = coalesce(undef, "", "default");
        }
    } 'coalesce does not leak';
};

subtest 'memo' => sub {
    no_leaks_ok {
        for (1..100) {
            my $count = 0;
            my $fn = memo(sub { $count++; $_[0] * 2 });
            $fn->(5);
            $fn->(5);  # cached
            $fn->(10);
            $fn->(10); # cached
        }
    } 'memo does not leak';
};

subtest 'lazy and force' => sub {
    no_leaks_ok {
        for (1..500) {
            my $expensive = lazy(sub { 42 * 2 });
            my $v1 = force($expensive);
            my $v2 = force($expensive);  # cached
        }
    } 'lazy/force does not leak';
};

done_testing();
