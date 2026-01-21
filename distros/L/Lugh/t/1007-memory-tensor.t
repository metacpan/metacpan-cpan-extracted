#!/usr/bin/env perl
# t/1007-memory-tensor.t - Memory leak tests for Lugh::Tensor

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Test::LeakTrace; Test::LeakTrace->import(); };
    if ($@) {
        plan skip_all => 'Test::LeakTrace required for memory leak tests';
    }
}

use Lugh;

# Warmup
{
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
}

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

subtest 'Tensor creation/destruction' => sub {
    leaks_stable {
        for (1..20) {
            my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
            my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
        }
    } 'Tensor lifecycle';
};

subtest 'Tensor with data' => sub {
    leaks_stable {
        for (1..10) {
            my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
            my $tensor = Lugh::Tensor->new_f32($ctx, 10);
            my @data = (1.0) x 10;
            $tensor->set_f32(@data);
            my @out = $tensor->get_f32();
        }
    } 'Tensor set/get';
};

subtest 'Multiple tensors same context' => sub {
    leaks_stable {
        my $ctx = Lugh::Context->new(mem_size => 64 * 1024 * 1024);
        for (1..50) {
            my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
        }
    } 'Multiple tensors';
};

subtest 'Tensor info access' => sub {
    leaks_stable {
        my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
        my $tensor = Lugh::Tensor->new_f32($ctx, 10, 10);
        for (1..100) {
            my $nelems = $tensor->nelements;
            my $ndims = $tensor->n_dims;
        }
    } 'Tensor info access';
};

subtest 'Different tensor shapes' => sub {
    leaks_stable {
        my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
        my $t1 = Lugh::Tensor->new_f32($ctx, 32);
        my $t2 = Lugh::Tensor->new_f32($ctx, 16, 16);
        my $t3 = Lugh::Tensor->new_f32($ctx, 8, 8, 4);
    } 'Different shapes';
};

subtest 'Large tensors' => sub {
    leaks_stable {
        for (1..3) {
            my $ctx = Lugh::Context->new(mem_size => 128 * 1024 * 1024);
            my $tensor = Lugh::Tensor->new_f32($ctx, 1024, 256);
        }
    } 'Large tensors';
};

done_testing();
