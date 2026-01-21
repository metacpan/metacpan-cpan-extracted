#!/usr/bin/env perl
# t/1000-memory-context.t - Memory leak tests for Lugh::Context

use strict;
use warnings;
use Test::More;
use FindBin;

BEGIN {
    eval { require Test::LeakTrace; Test::LeakTrace->import(); };
    if ($@) {
        plan skip_all => 'Test::LeakTrace required for memory leak tests';
    }
}

use Lugh;

# Warmup allocations
{
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    undef $ctx;
}

# Helper: Check leaks don't accumulate across runs
sub leaks_stable(&;$) {
    my ($code, $name) = @_;
    $name //= 'leaks stable';
    
    # Run 3 times to detect linear growth (real leak pattern)
    my $count1 = Test::LeakTrace::leaked_count { $code->() };
    my $count2 = Test::LeakTrace::leaked_count { $code->() };
    my $count3 = Test::LeakTrace::leaked_count { $code->() };
    
    # Real leak: counts grow linearly. Normal variance: counts stay similar
    my $growing = ($count3 > $count2 + 2) && ($count2 > $count1 + 2);
    # Also check absolute threshold - no run should have excessive leaks
    my $excessive = ($count3 > 50);
    
    my $ok = !$growing && !$excessive;
    ok($ok, $name) or diag("Runs: $count1 -> $count2 -> $count3" . 
        ($growing ? " (growing)" : "") . ($excessive ? " (excessive)" : ""));
    return $ok;
}

subtest 'Context creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
            undef $ctx;
        }
    } 'Context create/destroy cycle';
};

subtest 'Context with tensor creation' => sub {
    leaks_stable {
        for (1..10) {
            my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
            my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
            undef $tensor;
            undef $ctx;
        }
    } 'Context + Tensor cycle';
};

subtest 'Multiple contexts' => sub {
    leaks_stable {
        my @contexts;
        for (1..5) {
            push @contexts, Lugh::Context->new(mem_size => 4 * 1024 * 1024);
        }
        @contexts = ();
    } 'Multiple context lifecycle';
};

subtest 'Context reuse pattern' => sub {
    leaks_stable {
        my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
        for (1..10) {
            my $tensor = Lugh::Tensor->new_f32($ctx, 5, 5);
        }
        undef $ctx;
    } 'Context reuse with multiple tensors';
};

done_testing();
