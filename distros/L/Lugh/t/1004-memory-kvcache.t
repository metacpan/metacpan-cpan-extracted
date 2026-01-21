#!/usr/bin/env perl
# t/1004-memory-kvcache.t - Memory leak tests for Lugh::KVCache

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
    my $cache = $inference->create_kv_cache();
    my @logits = $inference->forward_cache($cache, \@prompt_tokens);
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

subtest 'KVCache creation/destruction' => sub {
    leaks_stable {
        for (1..10) {
            my $cache = $inference->create_kv_cache();
            undef $cache;
        }
    } 'KVCache lifecycle';
};

subtest 'KVCache forward' => sub {
    leaks_stable {
        for (1..5) {
            my $cache = $inference->create_kv_cache();
            my @logits = $inference->forward_cache($cache, \@prompt_tokens);
            undef $cache;
        }
    } 'KVCache forward cycle';
};

subtest 'KVCache incremental forward' => sub {
    leaks_stable {
        my $cache = $inference->create_kv_cache();
        my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        for (1..10) {
            my $token = $inference->sample_top_p(\@logits, 0.9, 1.0);
            @logits = $inference->forward_cache($cache, [$token]);
        }
        undef $cache;
    } 'Incremental forward';
};

subtest 'KVCache clear' => sub {
    leaks_stable {
        my $cache = $inference->create_kv_cache();
        for (1..10) {
            my @logits = $inference->forward_cache($cache, \@prompt_tokens);
            $cache->clear();
        }
        undef $cache;
    } 'Cache clear cycle';
};

subtest 'Multiple KVCaches' => sub {
    leaks_stable {
        my @caches;
        for (1..5) {
            push @caches, $inference->create_kv_cache();
        }
        for my $cache (@caches) {
            my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        }
        @caches = ();
    } 'Multiple caches';
};

subtest 'KVCache with generation' => sub {
    Lugh::srand(42);
    leaks_stable {
        my $cache = $inference->create_kv_cache();
        my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        
        for (1..10) {
            my $token = $inference->sample_top_p(\@logits, 0.9, 1.0);
            @logits = $inference->forward_cache($cache, [$token]);
        }
    } 'Generation with cache';
};

done_testing();
