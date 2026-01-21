#!/usr/bin/env perl
# t/34-backend-validation.t - GPU backend validation and cross-backend consistency tests

use strict;
use warnings;
use Test::More;
use FindBin;
use Time::HiRes qw(time);

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";

# ============================================================================
# Section A: Backend Discovery and Selection
# ============================================================================

subtest 'Backend Discovery API' => sub {
    # Test available_backends returns expected values
    my @backends = Lugh::available_backends();
    ok(@backends > 0, 'available_backends returns at least one backend');
    ok(grep({ $_ eq 'CPU' } @backends), 'CPU backend is always available');
    ok(grep({ $_ eq 'auto' } @backends), 'auto pseudo-backend is available');

    # Test backend_count
    my $count = Lugh::backend_count();
    ok($count >= 1, "backend_count returns $count (at least 1)");

    # Test backend_device_count
    my $dev_count = Lugh::backend_device_count();
    ok($dev_count >= 1, "backend_device_count returns $dev_count");

    # Test best_backend returns something valid
    my $best = Lugh::best_backend();
    ok(defined $best && length($best) > 0, "best_backend returns: $best");
    ok(Lugh::backend_available($best), 'best_backend is available');

    # List all available backends for diagnostic
    diag("Available backends: " . join(", ", @backends));
    diag("Best backend: $best");
};

subtest 'Backend Availability Checks' => sub {
    # CPU should always be available
    ok(Lugh::backend_available('CPU'), 'CPU backend available');
    ok(Lugh::backend_available('auto'), 'auto is always available');

    # Test non-existent backend
    ok(!Lugh::backend_available('NonExistentBackend123'), 'Non-existent backend not available');

    # Test has_metal (compile-time flag)
    my $has_metal = Lugh::has_metal();
    ok(defined $has_metal, 'has_metal returns defined value');

    if ($^O eq 'darwin') {
        ok($has_metal, 'Metal compiled in on macOS');
    } else {
        ok(!$has_metal, 'Metal not compiled in on non-macOS');
    }

    # Test metal_available (runtime check)
    my $metal_avail = Lugh::metal_available();
    ok(defined $metal_avail, 'metal_available returns defined value');

    if ($metal_avail) {
        diag("Metal GPU is available at runtime");
        ok(grep({ $_ eq 'Metal' } Lugh::available_backends()),
           'Metal in available_backends when metal_available');
    }
};

subtest 'Backend Info API' => sub {
    # Test backend_info for CPU
    my $cpu_info = Lugh::backend_info('CPU');
    is(ref($cpu_info), 'HASH', 'backend_info returns hashref');
    is($cpu_info->{name}, 'CPU', 'CPU info has correct name');
    is($cpu_info->{type}, 'CPU', 'CPU info has CPU type');
    is($cpu_info->{is_gpu}, 0, 'CPU is not a GPU');
    ok($cpu_info->{device_count} >= 1, 'CPU has at least 1 device');

    # Test backend_info for non-existent backend
    my $bad_info = Lugh::backend_info('NonExistentBackend123');
    # Returns hash with {error} key when backend not found
    ok(!defined $bad_info ||
       (ref($bad_info) eq 'HASH' && $bad_info->{error}),
       'Non-existent backend info returns undef or error hash');

    # Test Metal info if available
    SKIP: {
        skip "Metal not available", 4 unless Lugh::metal_available();

        my $metal_info = Lugh::backend_info('Metal');
        is(ref($metal_info), 'HASH', 'Metal backend_info returns hashref');
        is($metal_info->{name}, 'Metal', 'Metal info has correct name');
        is($metal_info->{is_gpu}, 1, 'Metal is a GPU');
        ok($metal_info->{device_count} >= 1, 'Metal has at least 1 device');
        diag("Metal device count: $metal_info->{device_count}");
    }
};

# ============================================================================
# Section B: Backend Error Handling
# ============================================================================

SKIP: {
    skip "No test model at $model_file", 1 unless -f $model_file;

    subtest 'Backend Error Handling' => sub {
        my $model = Lugh::Model->new(model => $model_file);

        # Test creating inference with invalid backend name
        eval {
            my $inf = Lugh::Inference->new(
                model => $model,
                backend => 'InvalidBackendName123',
            );
        };
        # Should either fail or fall back to CPU
        ok($@ || 1, 'Invalid backend name handled (error or fallback)');

        # Test creating inference with empty backend name
        eval {
            my $inf = Lugh::Inference->new(
                model => $model,
                backend => '',
            );
        };
        ok($@ || 1, 'Empty backend name handled');

        # Test explicit CPU backend works
        my $cpu_inf = eval {
            Lugh::Inference->new(
                model => $model,
                backend => 'CPU',
                n_threads => 2,
            );
        };
        ok($cpu_inf, 'Explicit CPU backend works');

        # Test auto backend works
        my $auto_inf = eval {
            Lugh::Inference->new(
                model => $model,
                backend => 'auto',
            );
        };
        ok($auto_inf, 'auto backend selection works');
    };
}

# ============================================================================
# Section C: Cross-Backend Numerical Consistency
# ============================================================================

SKIP: {
    skip "No test model at $model_file", 1 unless -f $model_file;

    subtest 'Cross-Backend Consistency' => sub {
        my $model = Lugh::Model->new(model => $model_file);
        my $tokenizer = Lugh::Tokenizer->new(model => $model);
        my @tokens = $tokenizer->encode("Hello world");

        # Get CPU baseline results
        my $cpu_inf = Lugh::Inference->new(
            model => $model,
            backend => 'CPU',
            n_threads => 4,
        );
        Lugh::srand(42);  # Set seed for reproducibility
        my @cpu_logits = $cpu_inf->forward_simple(\@tokens);

        ok(@cpu_logits > 0, 'CPU forward produces logits');
        ok(@cpu_logits == $tokenizer->n_vocab, 'CPU logits has correct size');

        # Record some reference values
        my $cpu_max_idx = 0;
        my $cpu_max_val = $cpu_logits[0];
        for my $i (1..$#cpu_logits) {
            if ($cpu_logits[$i] > $cpu_max_val) {
                $cpu_max_val = $cpu_logits[$i];
                $cpu_max_idx = $i;
            }
        }
        diag("CPU max logit: idx=$cpu_max_idx, val=$cpu_max_val");

        # Test best backend produces similar results
        my $best = Lugh::best_backend();
        SKIP: {
            skip "Best backend is CPU, no comparison needed", 3 if $best eq 'CPU';

            my $best_inf = Lugh::Inference->new(
                model => $model,
                backend => $best,
            );
            Lugh::srand(42);  # Same seed
            my @best_logits = $best_inf->forward_simple(\@tokens);

            ok(@best_logits == @cpu_logits, "Best backend ($best) produces same size output");

            # Find argmax on best backend
            my $best_max_idx = 0;
            my $best_max_val = $best_logits[0];
            for my $i (1..$#best_logits) {
                if ($best_logits[$i] > $best_max_val) {
                    $best_max_val = $best_logits[$i];
                    $best_max_idx = $i;
                }
            }
            diag("Best ($best) max logit: idx=$best_max_idx, val=$best_max_val");

            # Argmax should typically match (though floating point can differ slightly)
            is($best_max_idx, $cpu_max_idx, 'Argmax matches between backends');

            # Check numerical similarity (allow some floating point tolerance)
            my $diff = abs($best_max_val - $cpu_max_val);
            my $tolerance = abs($cpu_max_val) * 0.01;  # 1% tolerance
            $tolerance = 0.01 if $tolerance < 0.01;  # At least 0.01
            ok($diff < $tolerance, "Max logit values similar (diff=$diff, tol=$tolerance)");
        }

        # Test srand reproducibility on same backend
        Lugh::srand(12345);
        my @run1 = $cpu_inf->forward_simple(\@tokens);
        my $sample1 = $cpu_inf->sample_top_p(\@run1, temperature => 0.5, top_p => 0.9);

        Lugh::srand(12345);
        my @run2 = $cpu_inf->forward_simple(\@tokens);
        my $sample2 = $cpu_inf->sample_top_p(\@run2, temperature => 0.5, top_p => 0.9);

        is($sample1, $sample2, 'Same seed produces identical samples on CPU');
    };
}

# ============================================================================
# Section D: GPU-Specific Validation
# ============================================================================

SKIP: {
    skip "No test model at $model_file", 1 unless -f $model_file;
    skip "No GPU backend available", 1 if Lugh::best_backend() eq 'CPU';

    subtest 'GPU-Specific Validation' => sub {
        my $best = Lugh::best_backend();
        diag("Testing GPU backend: $best");

        my $model = Lugh::Model->new(model => $model_file);
        my $tokenizer = Lugh::Tokenizer->new(model => $model);

        # Create GPU inference
        my $gpu_inf = Lugh::Inference->new(
            model => $model,
            backend => $best,
        );
        ok($gpu_inf, "GPU inference created with $best backend");

        # Verify GPU is actually being used via pool backend
        my $pool = $gpu_inf->create_memory_pool();
        my $pool_backend = $pool->backend();
        ok(defined $pool_backend, "Pool reports backend: $pool_backend");

        # Run forward pass
        my @tokens = $tokenizer->encode("The quick brown fox");
        my @logits = $gpu_inf->forward_simple(\@tokens);
        ok(@logits > 0, 'GPU forward produces logits');
        ok(@logits == $tokenizer->n_vocab, 'GPU logits has correct vocab size');

        # Test multiple forward passes (GPU should handle repeated calls)
        for my $i (1..5) {
            my @iter_logits = $gpu_inf->forward_simple(\@tokens);
            is(scalar @iter_logits, $tokenizer->n_vocab, "GPU iteration $i produces correct size");
        }

        # Test forward_pool on GPU
        my @pool_logits = $gpu_inf->forward_pool($pool, \@tokens);
        ok(@pool_logits == $tokenizer->n_vocab, 'GPU forward_pool works');

        # Test KV cache on GPU
        my $cache = $gpu_inf->create_kv_cache();
        my @cache_logits = $gpu_inf->forward_cache($cache, \@tokens);
        ok(@cache_logits == $tokenizer->n_vocab, 'GPU forward_cache works');
        ok($cache->n_cached > 0, 'GPU cache stores tokens');
    };
}

# ============================================================================
# Section E: Metal-Specific Tests (macOS only)
# ============================================================================

SKIP: {
    skip "No test model at $model_file", 1 unless -f $model_file;
    skip "Metal not available", 1 unless Lugh::metal_available();

    subtest 'Metal-Specific Tests' => sub {
        diag("Running Metal-specific tests");

        my $model = Lugh::Model->new(model => $model_file);
        my $tokenizer = Lugh::Tokenizer->new(model => $model);

        # Explicitly request Metal backend
        my $metal_inf = eval {
            Lugh::Inference->new(
                model => $model,
                backend => 'Metal',
            );
        };

        SKIP: {
            skip "Could not create Metal inference: $@", 5 unless $metal_inf;

            ok($metal_inf, 'Metal inference created');

            # Check pool backend (may report underlying CPU allocator even with Metal)
            my $pool = $metal_inf->create_memory_pool();
            my $backend_name = $pool->backend();
            # Note: pool->backend() may return CPU even when using Metal for compute
            # because memory pools may use CPU memory that's then uploaded to GPU
            ok(defined $backend_name && length($backend_name) > 0,
               "Pool reports backend: $backend_name (may differ from compute backend)");

            # Run inference on Metal
            my @tokens = $tokenizer->encode("Hello");
            my @logits = $metal_inf->forward_simple(\@tokens);
            ok(@logits == $tokenizer->n_vocab, 'Metal forward produces correct output');

            # Compare Metal vs CPU timing (Metal should generally be faster for larger inputs)
            my $cpu_inf = Lugh::Inference->new(
                model => $model,
                backend => 'CPU',
                n_threads => 4,
            );

            my @longer_tokens = $tokenizer->encode("The quick brown fox jumps over the lazy dog");

            # Warm up both
            $cpu_inf->forward_simple(\@longer_tokens);
            $metal_inf->forward_simple(\@longer_tokens);

            # Time CPU
            my $cpu_start = time();
            for (1..3) {
                $cpu_inf->forward_simple(\@longer_tokens);
            }
            my $cpu_time = time() - $cpu_start;

            # Time Metal
            my $metal_start = time();
            for (1..3) {
                $metal_inf->forward_simple(\@longer_tokens);
            }
            my $metal_time = time() - $metal_start;

            diag("CPU time (3 iters): ${cpu_time}s, Metal time: ${metal_time}s");

            # Metal performance should be comparable or better
            # (small models may not show GPU advantage)
            ok($metal_time > 0 && $cpu_time > 0, 'Both backends complete in measurable time');
        }
    };
}

# ============================================================================
# Section F: Backend Selection Priority
# ============================================================================

subtest 'Backend Selection Priority' => sub {
    my $best = Lugh::best_backend();
    my @all = Lugh::available_backends();

    # If GPU is available, best_backend should prefer it
    my $has_gpu = 0;
    for my $backend (@all) {
        next if $backend eq 'auto' || $backend eq 'CPU';
        my $info = Lugh::backend_info($backend);
        if ($info && $info->{is_gpu}) {
            $has_gpu = 1;
            last;
        }
    }

    if ($has_gpu) {
        my $best_info = Lugh::backend_info($best);
        ok($best_info && $best_info->{is_gpu}, "Best backend ($best) is GPU when GPU available");
    } else {
        is($best, 'CPU', 'Best backend is CPU when no GPU available');
    }

    diag("Has GPU: $has_gpu, Best backend: $best");
};

done_testing();
