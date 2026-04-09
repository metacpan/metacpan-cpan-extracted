#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Func::Util qw(
    compose pipeline partial negate once
    memo lazy force always identity noop
);

# ============================================
# Higher-Order Function Integration Tests
# ============================================

subtest 'compose - function composition' => sub {
    my $double = sub { $_[0] * 2 };
    my $inc = sub { $_[0] + 1 };
    my $square = sub { $_[0] ** 2 };

    # Basic composition: (f ∘ g)(x) = f(g(x))
    my $double_then_inc = compose($inc, $double);
    is($double_then_inc->(5), 11, 'compose: 5*2+1 = 11');

    my $inc_then_double = compose($double, $inc);
    is($inc_then_double->(5), 12, 'compose: (5+1)*2 = 12');

    # Triple composition
    my $triple = compose($inc, compose($double, $square));
    is($triple->(3), 19, 'compose 3 fns: (3^2)*2+1 = 19');
};

subtest 'pipeline - data transformation' => sub {
    # Simulating data processing pipeline
    my @transforms = (
        sub { $_[0] * 2 },      # double
        sub { $_[0] + 10 },     # add 10
        sub { $_[0] / 2 },      # halve
    );

    is(pipeline(5, @transforms), 10, 'pipeline: (5*2+10)/2 = 10');
    is(pipeline(0, @transforms), 5, 'pipeline: (0*2+10)/2 = 5');

    # String processing pipeline
    my @str_transforms = (
        sub { lc($_[0]) },
        sub { my $s = $_[0]; $s =~ s/\s+/_/g; $s },
        sub { "prefix_$_[0]" },
    );
    is(pipeline("Hello World", @str_transforms), 'prefix_hello_world', 'string pipeline');
};

subtest 'partial - currying/partial application' => sub {
    my $add = sub { $_[0] + $_[1] };
    my $mul = sub { $_[0] * $_[1] };
    my $div = sub { $_[0] / $_[1] };

    my $add5 = partial($add, 5);
    is($add5->(3), 8, 'partial add: 5+3');
    is($add5->(10), 15, 'partial add: 5+10');

    my $times10 = partial($mul, 10);
    is($times10->(7), 70, 'partial mul: 10*7');

    # Partial with string function
    my $greet = sub { "$_[0], $_[1]!" };
    my $hello = partial($greet, "Hello");
    is($hello->("World"), "Hello, World!", 'partial greet');
    is($hello->("Alice"), "Hello, Alice!", 'partial greet 2');
};

subtest 'negate - predicate negation' => sub {
    my $is_even = sub { $_[0] % 2 == 0 };
    my $is_odd = negate($is_even);

    ok($is_even->(4), 'original: 4 is even');
    ok(!$is_even->(3), 'original: 3 is not even');
    ok($is_odd->(3), 'negated: 3 is odd');
    ok(!$is_odd->(4), 'negated: 4 is not odd');

    # Negate with multiple args
    my $both_positive = sub { $_[0] > 0 && $_[1] > 0 };
    my $any_non_positive = negate($both_positive);
    ok($both_positive->(1, 2), 'both positive: 1, 2');
    ok($any_non_positive->(-1, 2), 'negated: -1, 2');
    ok($any_non_positive->(1, -2), 'negated: 1, -2');
};

subtest 'once - single execution' => sub {
    my $call_count = 0;
    my $increment = once(sub { ++$call_count; return "called" });

    is($increment->(), "called", 'once: first call');
    is($call_count, 1, 'once: count is 1');

    $increment->();
    $increment->();
    $increment->();
    is($call_count, 1, 'once: still 1 after multiple calls');

    # Once with return value
    my $get_id = once(sub { int(rand(1000000)) });
    my $first_id = $get_id->();
    is($get_id->(), $first_id, 'once: returns same value');
    is($get_id->(), $first_id, 'once: still same value');
};

subtest 'memo - memoization' => sub {
    my $compute_count = 0;
    my $slow_fib;
    $slow_fib = memo(sub {
        my $n = $_[0];
        $compute_count++;
        return $n if $n <= 1;
        return $slow_fib->($n - 1) + $slow_fib->($n - 2);
    });

    is($slow_fib->(10), 55, 'memo fib(10) = 55');

    # Reset and compute again - should hit cache
    my $prev_count = $compute_count;
    is($slow_fib->(10), 55, 'memo fib(10) cached');
    is($compute_count, $prev_count, 'memo: no additional computations');

    # Simple memoization test
    my $calls = 0;
    my $memoized = memo(sub { $calls++; $_[0] * 2 });
    is($memoized->(5), 10, 'memo: 5*2');
    is($memoized->(5), 10, 'memo: cached 5*2');
    is($calls, 1, 'memo: only called once');
};

subtest 'lazy - deferred evaluation' => sub {
    my $evaluated = 0;
    my $lazy_val = lazy(sub { $evaluated = 1; return 42 });

    is($evaluated, 0, 'lazy: not evaluated yet');
    my $result = force($lazy_val);
    is($evaluated, 1, 'lazy: now evaluated');
    is($result, 42, 'lazy: correct value');

    # Multiple force calls don't re-evaluate
    $evaluated = 0;
    my $lazy2 = lazy(sub { $evaluated++; return "hello" });
    force($lazy2);
    force($lazy2);
    force($lazy2);
    is($evaluated, 1, 'lazy: evaluated only once');
};

subtest 'always - constant function' => sub {
    my $always_42 = always(42);
    is($always_42->(), 42, 'always: returns constant');
    is($always_42->(1, 2, 3), 42, 'always: ignores args');
    is($always_42->("any", "thing"), 42, 'always: still ignores args');

    my $always_ref = always({ key => 'value' });
    is_deeply($always_ref->(), { key => 'value' }, 'always: works with refs');
};

subtest 'identity - pass-through' => sub {
    is(identity(42), 42, 'identity: number');
    is(identity("hello"), "hello", 'identity: string');
    is(identity(undef), undef, 'identity: undef');

    my $ref = [1, 2, 3];
    is(identity($ref), $ref, 'identity: same ref');
};

subtest 'noop - do nothing' => sub {
    my $result = noop();
    ok(!defined $result, 'noop: returns nothing');

    $result = noop(1, 2, 3, 4, 5);
    ok(!defined $result, 'noop: ignores all args');
};

subtest 'combined workflows' => sub {
    # Build a data processing pipeline with memoization
    my $expensive = memo(sub { $_[0] ** 2 });
    my $process = compose(
        sub { $_[0] + 1 },
        $expensive
    );

    is($process->(5), 26, 'combined: (5^2)+1 = 26');

    # Predicate combination
    my $is_positive = sub { $_[0] > 0 };
    my $is_even = sub { $_[0] % 2 == 0 };
    my $is_non_positive = negate($is_positive);

    ok($is_positive->(5), 'positive check');
    ok($is_non_positive->(-5), 'negated positive check');

    # Using partial with pipeline
    my $add = sub { $_[0] + $_[1] };
    my $add10 = partial($add, 10);
    my $add20 = partial($add, 20);

    is(pipeline(5, $add10, $add20), 35, 'partial in pipeline: 5+10+20');
};

subtest 'real-world use case: validation chain' => sub {
    # Build validators using HOFs
    my $not_empty = sub { defined $_[0] && length($_[0]) > 0 };
    my $max_len = sub { my $max = $_[0]; sub { length($_[0]) <= $max } };
    my $min_len = sub { my $min = $_[0]; sub { length($_[0]) >= $min } };

    my $validate_username = sub {
        my $val = $_[0];
        return 0 unless $not_empty->($val);
        return 0 unless $min_len->(3)->($val);
        return 0 unless $max_len->(20)->($val);
        return 1;
    };

    ok($validate_username->("alice"), 'valid username');
    ok(!$validate_username->("ab"), 'too short');
    ok(!$validate_username->("a" x 25), 'too long');
    ok(!$validate_username->(""), 'empty');
};

subtest 'real-world use case: retry logic' => sub {
    my $attempts = 0;
    my $fail_twice = sub {
        $attempts++;
        die "fail" if $attempts <= 2;
        return "success";
    };

    # Memoize to cache successful result
    my $cached_op = memo(sub {
        my $result;
        for (1..3) {
            eval { $result = $fail_twice->() };
            return $result if defined $result;
        }
        return undef;
    });

    is($cached_op->(), "success", 'retry succeeds');
    is($attempts, 3, 'tried 3 times');

    # Second call uses cache
    $attempts = 0;
    is($cached_op->(), "success", 'cached result');
    is($attempts, 0, 'no new attempts');
};

done_testing();
