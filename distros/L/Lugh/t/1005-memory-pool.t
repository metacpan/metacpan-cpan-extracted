#!/usr/bin/env perl
# t/1005-memory-pool.t - Memory leak tests for Lugh::MemoryPool

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

# Setup
my $model = Lugh::Model->new(model => $model_file);
my $tokenizer = Lugh::Tokenizer->new(model => $model);
my $inference = Lugh::Inference->new(model => $model);
my @prompt_tokens = $tokenizer->encode("Once upon a time");

# Warmup
{
    my $pool = $inference->create_memory_pool();
    my @logits = $inference->forward_pool($pool, \@prompt_tokens);
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

subtest 'MemoryPool creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $pool = $inference->create_memory_pool();
            undef $pool;
        }
    } 'MemoryPool lifecycle';
};

subtest 'MemoryPool forward' => sub {
    leaks_stable {
        for (1..5) {
            my $pool = $inference->create_memory_pool();
            my @logits = $inference->forward_pool($pool, \@prompt_tokens);
            undef $pool;
        }
    } 'Pool forward cycle';
};

subtest 'MemoryPool reuse' => sub {
    leaks_stable {
        my $pool = $inference->create_memory_pool();
        for (1..20) {
            my @logits = $inference->forward_pool($pool, \@prompt_tokens);
        }
        undef $pool;
    } 'Pool reuse';
};

subtest 'Multiple MemoryPools' => sub {
    leaks_stable {
        my @pools;
        for (1..5) {
            push @pools, $inference->create_memory_pool();
        }
        for my $pool (@pools) {
            my @logits = $inference->forward_pool($pool, \@prompt_tokens);
        }
        @pools = ();
    } 'Multiple pools';
};

subtest 'Pool with varying input sizes' => sub {
    leaks_stable {
        my $pool = $inference->create_memory_pool();
        for my $len (2, 5, 10, 20, 5, 2) {
            my @tokens = @prompt_tokens[0..($len-1 > $#prompt_tokens ? $#prompt_tokens : $len-1)];
            push @tokens, $prompt_tokens[0] while @tokens < $len;
            my @logits = $inference->forward_pool($pool, \@tokens);
        }
    } 'Varying input sizes';
};

done_testing();
