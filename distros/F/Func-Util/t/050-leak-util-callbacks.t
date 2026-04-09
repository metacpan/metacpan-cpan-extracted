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
    any_cb all_cb none_cb first_cb grep_cb count_cb partition_cb final_cb
    register_callback has_callback list_callbacks
);

# Test data - create outside of leak tests
my @numbers = (-5, -2, 0, 1, 3, 5, 8, 10, 12);
my @mixed = (undef, "", 0, 1, "hello", [], {});

# Warmup
for (1..10) {
    any_cb(\@numbers, ':is_positive');
    all_cb(\@numbers, ':is_defined');
    first_cb(\@numbers, ':is_zero');
}

# ==== Built-in predicate callbacks ====

subtest 'any_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_cb(\@numbers, ':is_positive');
            my $r2 = any_cb(\@numbers, ':is_negative');
            my $r3 = any_cb(\@numbers, ':is_zero');
            my $r4 = any_cb(\@numbers, ':is_even');
            my $r5 = any_cb(\@numbers, ':is_odd');
        }
    } 'any_cb does not leak';
};

subtest 'all_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = all_cb(\@numbers, ':is_defined');
            my $r2 = all_cb(\@numbers, ':is_positive');  # false
            my $r3 = all_cb(\@numbers, ':is_number');
        }
    } 'all_cb does not leak';
};

subtest 'none_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = none_cb(\@numbers, ':is_ref');  # true - no refs
            my $r2 = none_cb(\@numbers, ':is_positive');  # false
        }
    } 'none_cb does not leak';
};

subtest 'first_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = first_cb(\@numbers, ':is_positive');
            my $r2 = first_cb(\@numbers, ':is_zero');
            my $r3 = first_cb(\@numbers, ':is_negative');
        }
    } 'first_cb does not leak';
};

subtest 'grep_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my @r1 = grep_cb(\@numbers, ':is_positive');
            my @r2 = grep_cb(\@numbers, ':is_even');
            my @r3 = grep_cb(\@numbers, ':is_negative');
        }
    } 'grep_cb does not leak';
};

subtest 'count_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = count_cb(\@numbers, ':is_positive');
            my $r2 = count_cb(\@numbers, ':is_even');
            my $r3 = count_cb(\@numbers, ':is_zero');
        }
    } 'count_cb does not leak';
};

subtest 'partition_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my ($pos, $neg) = partition_cb(\@numbers, ':is_positive');
            my ($even, $odd) = partition_cb(\@numbers, ':is_even');
        }
    } 'partition_cb does not leak';
};

subtest 'final_cb with built-in predicates' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = final_cb(\@numbers, ':is_positive');
            my $r2 = final_cb(\@numbers, ':is_negative');
            my $r3 = final_cb(\@numbers, ':is_even');
        }
    } 'final_cb does not leak';
};

# ==== Callback registry management ====

subtest 'has_callback' => sub {
    no_leaks_ok {
        for (1..1000) {
            my $r1 = has_callback(':is_positive');
            my $r2 = has_callback(':is_defined');
            my $r3 = has_callback('nonexistent_callback');
        }
    } 'has_callback does not leak';
};

subtest 'list_callbacks' => sub {
    no_leaks_ok {
        for (1..500) {
            my $callbacks = list_callbacks();
        }
    } 'list_callbacks does not leak';
};

# ==== User-registered callbacks ====

# Register a custom callback once before testing
eval { register_callback('is_big', sub { $_[0] > 5 }) };

subtest 'register_callback usage' => sub {
    plan skip_all => 'Custom callback not registered' unless has_callback('is_big');

    no_leaks_ok {
        for (1..500) {
            my $r1 = any_cb(\@numbers, 'is_big');
            my $r2 = first_cb(\@numbers, 'is_big');
            my $r3 = count_cb(\@numbers, 'is_big');
        }
    } 'custom callback usage does not leak';
};

# ==== More built-in predicates ====

subtest 'type predicates via callbacks' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_cb(\@mixed, ':is_array');
            my $r2 = any_cb(\@mixed, ':is_hash');
            my $r3 = any_cb(\@mixed, ':is_ref');
            my $r4 = first_cb(\@mixed, ':is_string');
        }
    } 'type predicates via callbacks do not leak';
};

subtest 'truthiness predicates via callbacks' => sub {
    no_leaks_ok {
        for (1..500) {
            my $r1 = any_cb(\@mixed, ':is_true');
            my $r2 = any_cb(\@mixed, ':is_false');
            my $r3 = count_cb(\@mixed, ':is_defined');
            my $r4 = count_cb(\@mixed, ':is_empty');
        }
    } 'truthiness predicates via callbacks do not leak';
};

done_testing();
