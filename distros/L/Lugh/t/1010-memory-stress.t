#!/usr/bin/env perl
# t/1010-memory-stress.t - Memory stress tests for Lugh

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
    my @logits = $inference->forward_simple(\@prompt_tokens);
    my $cache = $inference->create_kv_cache();
    @logits = $inference->forward_cache($cache, \@prompt_tokens);
}

sub memory_growth_ok(&$$) {
    my ($code, $iterations, $name) = @_;
    
    # Run warmup
    $code->();
    
    my $before = Test::LeakTrace::leaked_count { 
        for (1..($iterations / 2)) { $code->() }
    };
    
    my $after = Test::LeakTrace::leaked_count { 
        for (1..$iterations) { $code->() }
    };
    
    # Memory should not grow linearly with iterations
    my $ratio = $before > 0 ? $after / $before : 1;
    my $ok = ($ratio < 2.5);
    ok($ok, $name) or diag("$iterations/2 iters: $before leaks, $iterations iters: $after leaks (ratio: $ratio)");
    return $ok;
}

subtest 'Stress: Repeated tokenization' => sub {
    memory_growth_ok {
        for my $text ("Hello", "Once upon a time", "The quick brown fox") {
            my @tokens = $tokenizer->encode($text);
            my $decoded = $tokenizer->decode(\@tokens);
        }
    } 100, 'Tokenization stress';
};

subtest 'Stress: Repeated forward passes' => sub {
    memory_growth_ok {
        my @logits = $inference->forward_simple(\@prompt_tokens);
        my $top = $inference->sample_top_p(\@logits, 0.9, 1.0);
    } 50, 'Forward pass stress';
};

subtest 'Stress: Cache create/destroy cycle' => sub {
    memory_growth_ok {
        my $cache = $inference->create_kv_cache();
        my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        undef $cache;
    } 50, 'Cache cycle stress';
};

subtest 'Stress: Pool create/destroy cycle' => sub {
    memory_growth_ok {
        my $pool = $inference->create_memory_pool();
        my @logits = $inference->forward_pool($pool, \@prompt_tokens);
        undef $pool;
    } 50, 'Pool cycle stress';
};

subtest 'Stress: Full generation loops' => sub {
    Lugh::srand(42);
    memory_growth_ok {
        my $cache = $inference->create_kv_cache();
        my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        for (1..5) {
            my $token = $inference->sample_top_p(\@logits, 0.9, 1.0);
            @logits = $inference->forward_cache($cache, [$token]);
        }
    } 20, 'Generation stress';
};

subtest 'Stress: Multiple components interleaved' => sub {
    Lugh::srand(42);
    memory_growth_ok {
        # Create various components
        my $cache = $inference->create_kv_cache();
        my $pool = $inference->create_memory_pool();
        
        # Use them
        my @logits1 = $inference->forward_cache($cache, \@prompt_tokens);
        my @logits2 = $inference->forward_pool($pool, \@prompt_tokens);
        
        # Sample
        my $t1 = $inference->sample_top_p(\@logits1, 0.9, 1.0);
        my $t2 = $inference->sample_top_k(\@logits2, 40, 1.0);
        
        # Clean up
        undef $pool;
        undef $cache;
    } 30, 'Interleaved component stress';
};

subtest 'Stress: Rapid object creation' => sub {
    memory_growth_ok {
        for (1..10) {
            my $inf = Lugh::Inference->new(model => $model);
            my $tok = Lugh::Tokenizer->new(model => $model);
            my @tokens = $tok->encode("test");
            my @logits = $inf->forward_simple(\@tokens);
        }
    } 10, 'Object creation stress';
};

done_testing();
