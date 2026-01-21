#!/usr/bin/env perl
# t/1001-memory-model.t - Memory leak tests for Lugh::Model

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

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Warmup - first load may have one-time allocations
{
    my $model = Lugh::Model->new(model => $model_file);
    undef $model;
}

# Helper: Check leaks don't accumulate
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

subtest 'Model load/unload cycle' => sub {
    leaks_stable {
        for (1..5) {
            my $model = Lugh::Model->new(model => $model_file);
            undef $model;
        }
    } 'Model load/unload';
};

subtest 'Model with metadata access' => sub {
    leaks_stable {
        for (1..5) {
            my $model = Lugh::Model->new(model => $model_file);
            my $arch = $model->architecture;
            my $tensors = $model->n_tensors;
            undef $model;
        }
    } 'Model metadata access';
};

subtest 'Model tensor access' => sub {
    leaks_stable {
        for (1..5) {
            my $model = Lugh::Model->new(model => $model_file);
            my @names = $model->tensor_names;
            for my $name (@names[0..2]) {
                my $info = $model->tensor_info($name);
            }
            undef $model;
        }
    } 'Model tensor info access';
};

subtest 'Multiple models' => sub {
    leaks_stable {
        my @models;
        for (1..3) {
            push @models, Lugh::Model->new(model => $model_file);
        }
        @models = ();
    } 'Multiple model lifecycle';
};

done_testing();
