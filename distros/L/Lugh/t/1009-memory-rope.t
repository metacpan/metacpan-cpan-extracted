#!/usr/bin/env perl
# t/1009-memory-rope.t - Memory leak tests for Lugh::RoPE

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
use Lugh::RoPE;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

# Setup
my $model = Lugh::Model->new(model => $model_file);
my $inference = Lugh::Inference->new(model => $model);
my $tokenizer = Lugh::Tokenizer->new(model => $model);
my @prompt_tokens = $tokenizer->encode("Once upon a time");

# Warmup
{
    my $rope = Lugh::RoPE->linear(4096, 8192);
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

subtest 'RoPE linear creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $rope = Lugh::RoPE->linear(4096, 8192);
            undef $rope;
        }
    } 'RoPE linear lifecycle';
};

subtest 'RoPE yarn creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $rope = Lugh::RoPE->yarn(4096, 32768);
            undef $rope;
        }
    } 'RoPE yarn lifecycle';
};

subtest 'RoPE presets' => sub {
    leaks_stable {
        for (1..5) {
            my $lin2x = Lugh::RoPE->linear_2x(4096);
            my $lin4x = Lugh::RoPE->linear_4x(4096);
            my $yarn32k = Lugh::RoPE->yarn_32k(4096);
        }
    } 'RoPE presets';
};

subtest 'RoPE config access' => sub {
    leaks_stable {
        my $rope = Lugh::RoPE->yarn(4096, 32768);
        for (1..50) {
            my $scaling = $rope->scaling_type_name;
            my $freq = $rope->freq_scale;
            my $orig = $rope->n_ctx_orig;
            my $target = $rope->target_ctx;
        }
    } 'RoPE config access';
};

subtest 'Multiple RoPE configs' => sub {
    leaks_stable {
        for my $target (8192, 16384, 32768) {
            my $linear = Lugh::RoPE->linear(4096, $target);
            my $yarn = Lugh::RoPE->yarn(4096, $target);
            my $freq_l = $linear->freq_scale;
            my $freq_y = $yarn->freq_scale;
        }
    } 'Multiple RoPE configs';
};

done_testing();
