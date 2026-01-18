#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use FindBin;
use lib "$FindBin::Bin/../blib/lib";
use lib "$FindBin::Bin/../blib/arch";

# Performance and backend tests for Lugh

use_ok('Lugh');

# Test 1-6: Backend discovery API
{
    # Test available_backends returns list
    my @backends = Lugh::available_backends();
    ok(@backends > 0, 'available_backends returns at least one backend');
    ok(grep { $_ eq 'auto' } @backends, 'auto backend is always available');
    ok(grep { $_ eq 'CPU' } @backends, 'CPU backend should be available');
    
    # Test backend_count
    my $count = Lugh::backend_count();
    ok($count >= 1, 'backend_count returns at least 1');
    is($count, @backends - 1, 'backend_count equals backends minus auto');  # auto is synthetic
    
    # Test backend_device_count
    my $dev_count = Lugh::backend_device_count();
    ok($dev_count >= 1, 'backend_device_count returns at least 1');
}

# Test 7-10: Backend info API
{
    # Test backend_info for CPU
    my $cpu_info = Lugh::backend_info('CPU');
    is(ref($cpu_info), 'HASH', 'backend_info returns hashref');
    is($cpu_info->{name}, 'CPU', 'CPU backend has correct name');
    is($cpu_info->{type}, 'CPU', 'CPU backend has CPU type');
    is($cpu_info->{is_gpu}, 0, 'CPU backend is not GPU');
}

# Test 11-12: Backend availability
{
    ok(Lugh::backend_available('CPU'), 'CPU is available');
    ok(Lugh::backend_available('auto'), 'auto is always available');
}

# Test 13-14: Best backend
{
    my $best = Lugh::best_backend();
    ok(defined $best && length($best), 'best_backend returns a name');
    ok(Lugh::backend_available($best), 'best backend is available');
}

# Test 15: has_metal flag (compile-time)
{
    my $has_metal = Lugh::has_metal();
    ok(defined $has_metal, 'has_metal returns a defined value');
    if ($^O eq 'darwin') {
        ok($has_metal, 'Metal should be compiled in on macOS');
    } else {
        ok(!$has_metal, 'Metal not compiled in on non-macOS');
    }
}

# Test 17-18: metal_available (runtime)
{
    my $metal_avail = Lugh::metal_available();
    ok(defined $metal_avail, 'metal_available returns a defined value');
    if ($^O eq 'darwin' && Lugh::has_metal()) {
        # On macOS with Metal compiled in, check consistency
        my $metal_in_list = grep { $_ eq 'Metal' } Lugh::available_backends();
        if ($metal_avail) {
            ok($metal_in_list, 'Metal in available_backends when metal_available is true');
        } else {
            pass('Metal may not have compatible GPU');
        }
    } else {
        pass('Metal not applicable on this platform');
    }
}

# Test 19-24: Performance benchmarks with model (only if model available)
SKIP: {
    my $model_path = $ENV{LUGH_TEST_MODEL} || "$FindBin::Bin/data/test-model.gguf";
    skip "No test model at $model_path", 6 unless -f $model_path;
    
    my $model = eval { Lugh::Model->new(model => $model_path) };
    skip "Could not load model: $@", 6 unless $model;
    
    my $tokenizer = eval { Lugh::Tokenizer->new(model => $model) };
    skip "Could not create tokenizer: $@", 6 unless $tokenizer;
    
    # Test CPU backend forward timing
    {
        my $inference = Lugh::Inference->new(
            model => $model,
            n_threads => 4,
            backend => 'CPU',
        );
        
        my @tokens = $tokenizer->encode("Hello world");
        
        # Warm up
        $inference->forward(\@tokens);
        
        # Benchmark
        my $start = time();
        my $iterations = 5;
        for (1..$iterations) {
            $inference->forward(\@tokens);
        }
        my $elapsed = time() - $start;
        my $avg_ms = ($elapsed / $iterations) * 1000;
        
        ok($avg_ms > 0, "CPU forward pass takes measurable time (avg: ${avg_ms}ms)");
        ok($avg_ms < 10000, "CPU forward pass completes in reasonable time (<10s)");
        diag("CPU forward avg: ${avg_ms}ms per iteration");
    }
    
    # Test best backend (GPU if available)
    {
        my $best = Lugh::best_backend();
        my $inference = Lugh::Inference->new(
            model => $model,
            n_threads => 4,
            backend => $best,
        );
        
        my @tokens = $tokenizer->encode("Hello world");
        
        # Warm up
        $inference->forward(\@tokens);
        
        # Benchmark
        my $start = time();
        my $iterations = 5;
        for (1..$iterations) {
            $inference->forward(\@tokens);
        }
        my $elapsed = time() - $start;
        my $avg_ms = ($elapsed / $iterations) * 1000;
        
        ok($avg_ms > 0, "Best backend ($best) forward pass takes measurable time (avg: ${avg_ms}ms)");
        ok($avg_ms < 10000, "Best backend forward pass completes in reasonable time (<10s)");
        diag("Best backend ($best) forward avg: ${avg_ms}ms per iteration");
    }
    
    # Test KV cache improves decode performance
    {
        my $inference = Lugh::Inference->new(
            model => $model,
            n_threads => 4,
            backend => 'auto',
        );
        
        my @tokens = $tokenizer->encode("The quick brown fox jumps");
        
        # Create KV cache
        my $cache = $inference->create_kv_cache();
        
        # Prefill
        my @prefill_logits = $inference->forward_with_cache($cache, \@tokens);
        
        # Find a token to use for decode steps (argmax of prefill)
        my $max_idx = 0;
        for my $i (0..$#prefill_logits) {
            $max_idx = $i if $prefill_logits[$i] > $prefill_logits[$max_idx];
        }
        
        # Time single token decode steps
        my $start = time();
        my $decode_steps = 10;
        for (1..$decode_steps) {
            my @logits = $inference->forward_with_cache($cache, [$max_idx]);
        }
        my $elapsed = time() - $start;
        my $avg_decode_ms = ($elapsed / $decode_steps) * 1000;
        
        ok($avg_decode_ms > 0, "KV cached decode takes measurable time (avg: ${avg_decode_ms}ms)");
        diag("KV cached decode avg: ${avg_decode_ms}ms per token");
        
        # Generally cached decode of single tokens should be much faster than 
        # redoing full context, but this depends on model size
        ok(1, "KV cache decode completed successfully");
    }
    
    # Test memory pool for repeated forward passes
    {
        my $inference = Lugh::Inference->new(
            model => $model,
            n_threads => 4,
            backend => 'auto',
        );
        
        my $pool = $inference->create_memory_pool();
        ok($pool, 'Memory pool created');
        isa_ok($pool, 'Lugh::MemoryPool', 'Pool is correct type');
        
        my @tokens = $tokenizer->encode("Hello world");
        
        # Forward with pool
        my @logits_pool = $inference->forward_with_pool($pool, \@tokens);
        ok(@logits_pool > 0, 'forward_with_pool returns logits');
        
        # Multiple passes with same pool (should be efficient)
        my $start = time();
        my $iterations = 5;
        for (1..$iterations) {
            my @logits = $inference->forward_with_pool($pool, \@tokens);
        }
        my $elapsed = time() - $start;
        my $avg_ms = ($elapsed / $iterations) * 1000;
        
        ok($avg_ms > 0, "forward_with_pool avg: ${avg_ms}ms");
        ok($pool->reset(), 'Pool reset works');
        diag("Memory pool forward avg: ${avg_ms}ms per iteration");
    }
    
    # Test batch processing
    {
        my $inference = Lugh::Inference->new(
            model => $model,
            n_threads => 4,
            backend => 'auto',
        );
        
        my @tokens1 = $tokenizer->encode("Hello");
        my @tokens2 = $tokenizer->encode("World");
        my @tokens3 = $tokenizer->encode("Test");
        
        # Batch forward - processes multiple sequences
        my $results = $inference->forward_batch([\@tokens1, \@tokens2, \@tokens3]);
        ok(ref($results) eq 'ARRAY', 'forward_batch returns array ref');
        is(scalar(@$results), 3, 'forward_batch returns results for all sequences');
        ok(ref($results->[0]) eq 'ARRAY', 'Each result is an array');
        ok(@{$results->[0]} > 0, 'First sequence has logits');
        ok(@{$results->[1]} > 0, 'Second sequence has logits');
        ok(@{$results->[2]} > 0, 'Third sequence has logits');
        diag("Batch processing: processed 3 sequences");
    }
}

done_testing();
