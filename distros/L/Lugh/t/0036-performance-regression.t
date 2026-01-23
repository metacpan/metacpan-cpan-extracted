#!/usr/bin/env perl
# t/36-performance-regression.t - Performance regression testing and benchmarking

use strict;
use warnings;
use Test::More;
use FindBin;
use Time::HiRes qw(time);

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";

# ============================================================================
# Configuration
# ============================================================================

# Baseline timings can be set via environment variables
# These should be calibrated for your hardware
my $BASELINE_FORWARD_MS = $ENV{LUGH_BASELINE_FORWARD_MS} // 50;
my $BASELINE_DECODE_MS = $ENV{LUGH_BASELINE_DECODE_MS} // 10;
my $BASELINE_TOKENIZE_MS = $ENV{LUGH_BASELINE_TOKENIZE_MS} // 1;
my $TOLERANCE = $ENV{LUGH_PERF_TOLERANCE} // 0.50;  # 50% tolerance by default

# Number of iterations for benchmarks
my $WARMUP_ITERS = 2;
my $BENCH_ITERS = 5;

# ============================================================================
# Helper Functions
# ============================================================================

sub benchmark {
    my ($name, $iterations, $code) = @_;

    # Warmup
    for (1..$WARMUP_ITERS) {
        $code->();
    }

    # Benchmark
    my $start = time();
    for (1..$iterations) {
        $code->();
    }
    my $elapsed = time() - $start;

    my $avg_ms = ($elapsed / $iterations) * 1000;
    return $avg_ms;
}

sub check_regression {
    my ($name, $actual_ms, $baseline_ms, $tolerance) = @_;
    $tolerance //= $TOLERANCE;

    my $ratio = $actual_ms / $baseline_ms;
    my $within_tolerance = $ratio < (1 + $tolerance);

    my $status = $within_tolerance ? 'PASS' : 'REGRESSION';
    my $pct = sprintf("%.1f%%", ($ratio - 1) * 100);

    diag("$name: ${actual_ms}ms (baseline: ${baseline_ms}ms, ${pct} from baseline) [$status]");

    return $within_tolerance;
}

# ============================================================================
# Section A: Basic Timing Benchmarks
# ============================================================================

subtest 'Benchmark Infrastructure' => sub {
    # Test that our benchmark helper works
    my $result = benchmark("test", 3, sub { my $x = 0; $x++ for 1..1000; });
    ok($result >= 0, 'Benchmark returns non-negative time');
    ok($result < 1000, 'Benchmark completes in reasonable time');
    diag("Infrastructure test: ${result}ms");
};

SKIP: {
    skip "No test model at $model_file", 1 unless -f $model_file;

    # Load components
    my $model = Lugh::Model->new(model => $model_file);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model, n_threads => 4);

    ok($model, 'Model loaded for benchmarks');
    ok($tokenizer, 'Tokenizer created');
    ok($inference, 'Inference created');

    my $vocab_size = $tokenizer->n_vocab;
    diag("Vocab size: $vocab_size");

    # ============================================================================
    # Section B: Tokenization Performance
    # ============================================================================

    subtest 'Tokenization Performance' => sub {
        my $short_text = "Hello world";
        my $medium_text = "The quick brown fox jumps over the lazy dog. " x 5;
        my $long_text = "word " x 100;

        # Short text encoding
        my $short_encode_ms = benchmark("short_encode", $BENCH_ITERS * 10, sub {
            my @tokens = $tokenizer->encode($short_text);
        });
        ok($short_encode_ms > 0, "Short encode: ${short_encode_ms}ms");

        # Medium text encoding
        my $medium_encode_ms = benchmark("medium_encode", $BENCH_ITERS * 5, sub {
            my @tokens = $tokenizer->encode($medium_text);
        });
        ok($medium_encode_ms > 0, "Medium encode: ${medium_encode_ms}ms");

        # Long text encoding
        my $long_encode_ms = benchmark("long_encode", $BENCH_ITERS, sub {
            my @tokens = $tokenizer->encode($long_text);
        });
        ok($long_encode_ms > 0, "Long encode: ${long_encode_ms}ms");

        # Decoding
        my @tokens = $tokenizer->encode($medium_text);
        my $decode_ms = benchmark("decode", $BENCH_ITERS * 5, sub {
            my $text = $tokenizer->decode(\@tokens);
        });
        ok($decode_ms > 0, "Decode: ${decode_ms}ms");

        # Regression check
        ok(check_regression("tokenize", $short_encode_ms, $BASELINE_TOKENIZE_MS),
           "Tokenization within tolerance of baseline");
    };

    # ============================================================================
    # Section C: Forward Pass Performance
    # ============================================================================

    subtest 'Forward Pass Performance' => sub {
        my @short_tokens = $tokenizer->encode("Hello");
        my @medium_tokens = $tokenizer->encode("The quick brown fox jumps over");
        my @long_tokens = $tokenizer->encode("The quick brown fox " x 10);

        diag("Token counts: short=" . scalar(@short_tokens) .
             ", medium=" . scalar(@medium_tokens) .
             ", long=" . scalar(@long_tokens));

        # Short sequence forward
        my $short_ms = benchmark("forward_short", $BENCH_ITERS, sub {
            my @logits = $inference->forward_simple(\@short_tokens);
        });
        ok($short_ms > 0, "Short forward: ${short_ms}ms");

        # Medium sequence forward
        my $medium_ms = benchmark("forward_medium", $BENCH_ITERS, sub {
            my @logits = $inference->forward_simple(\@medium_tokens);
        });
        ok($medium_ms > 0, "Medium forward: ${medium_ms}ms");

        # Long sequence forward
        my $long_ms = benchmark("forward_long", $BENCH_ITERS, sub {
            my @logits = $inference->forward_simple(\@long_tokens);
        });
        ok($long_ms > 0, "Long forward: ${long_ms}ms");

        # Regression check
        ok(check_regression("forward_simple", $medium_ms, $BASELINE_FORWARD_MS),
           "Forward pass within tolerance of baseline");

        # Scaling analysis
        my $scaling_ratio = $long_ms / $short_ms;
        my $token_ratio = scalar(@long_tokens) / scalar(@short_tokens);
        diag("Scaling: ${token_ratio}x tokens -> ${scaling_ratio}x time");

        # Generally expect sublinear or linear scaling due to batched matmuls
        ok($scaling_ratio < $token_ratio * 2,
           "Time scaling reasonable (${scaling_ratio}x for ${token_ratio}x tokens)");
    };

    # ============================================================================
    # Section D: KV Cache Performance
    # ============================================================================

    subtest 'KV Cache Performance' => sub {
        my @prompt_tokens = $tokenizer->encode("The quick brown fox jumps over the lazy dog");
        my $next_token = $tokenizer->bos_id;  # Use BOS as decode token

        my $cache = $inference->create_kv_cache();

        # Prefill timing (process full prompt)
        my $prefill_ms = benchmark("prefill", $BENCH_ITERS, sub {
            $cache->clear();
            my @logits = $inference->forward_cache($cache, \@prompt_tokens);
        });
        ok($prefill_ms > 0, "Prefill: ${prefill_ms}ms");

        # Decode timing (single token with warm cache)
        $cache->clear();
        $inference->forward_cache($cache, \@prompt_tokens);  # Warm cache

        my $decode_ms = benchmark("decode", $BENCH_ITERS * 3, sub {
            my @logits = $inference->forward_cache($cache, [$next_token]);
        });
        ok($decode_ms > 0, "Decode (cached): ${decode_ms}ms");

        # Decode should be faster than prefill
        my $speedup = $prefill_ms / $decode_ms;
        diag("KV cache speedup: ${speedup}x (prefill ${prefill_ms}ms vs decode ${decode_ms}ms)");
        ok($decode_ms < $prefill_ms, "Cached decode faster than prefill");

        # Regression check
        ok(check_regression("cached_decode", $decode_ms, $BASELINE_DECODE_MS),
           "Cached decode within tolerance of baseline");
    };

    # ============================================================================
    # Section E: Memory Pool Performance
    # ============================================================================

    subtest 'Memory Pool Performance' => sub {
        my @tokens = $tokenizer->encode("Test input for memory pool");

        my $pool = $inference->create_memory_pool();
        ok($pool, 'Memory pool created');

        # First call (may include allocation overhead)
        my $first_ms = benchmark("pool_first", 1, sub {
            my @logits = $inference->forward_pool($pool, \@tokens);
        });

        # Subsequent calls (should reuse allocations)
        my $subsequent_ms = benchmark("pool_subsequent", $BENCH_ITERS, sub {
            my @logits = $inference->forward_pool($pool, \@tokens);
        });

        diag("Pool first call: ${first_ms}ms, subsequent avg: ${subsequent_ms}ms");

        # Subsequent should generally be same or faster
        ok($subsequent_ms > 0, "Pool forward works");

        # Compare to non-pool forward
        my $simple_ms = benchmark("simple_compare", $BENCH_ITERS, sub {
            my @logits = $inference->forward_simple(\@tokens);
        });

        diag("Pool vs simple: pool=${subsequent_ms}ms, simple=${simple_ms}ms");

        # Pool should be comparable (not necessarily faster for small inputs)
        my $pool_ratio = $subsequent_ms / $simple_ms;
        ok($pool_ratio < 2.0, "Pool overhead acceptable (ratio: $pool_ratio)");
    };

    # ============================================================================
    # Section F: Batch Processing Performance
    # ============================================================================

    subtest 'Batch Processing Performance' => sub {
        my @tokens1 = $tokenizer->encode("Hello");
        my @tokens2 = $tokenizer->encode("World");
        my @tokens3 = $tokenizer->encode("Test");
        my @tokens4 = $tokenizer->encode("Batch");

        # Single sequence timing (for comparison)
        my $single_ms = benchmark("single", $BENCH_ITERS, sub {
            my @logits = $inference->forward_simple(\@tokens1);
        });

        # Batch of 2
        my $batch2_ms = benchmark("batch2", $BENCH_ITERS, sub {
            my $results = $inference->forward_batch([\@tokens1, \@tokens2]);
        });

        # Batch of 4
        my $batch4_ms = benchmark("batch4", $BENCH_ITERS, sub {
            my $results = $inference->forward_batch([\@tokens1, \@tokens2, \@tokens3, \@tokens4]);
        });

        diag("Single: ${single_ms}ms, Batch2: ${batch2_ms}ms, Batch4: ${batch4_ms}ms");

        # Batch should show some efficiency (not 2x/4x time for 2x/4x sequences)
        my $batch2_efficiency = (2 * $single_ms) / $batch2_ms;
        my $batch4_efficiency = (4 * $single_ms) / $batch4_ms;

        diag("Batch efficiency: 2x=${batch2_efficiency}x, 4x=${batch4_efficiency}x");

        ok($batch2_ms < 4 * $single_ms, "Batch of 2 not 4x single time");
        ok($batch4_ms < 8 * $single_ms, "Batch of 4 not 8x single time");
    };

    # ============================================================================
    # Section G: Thread Scaling
    # ============================================================================

    subtest 'Thread Scaling' => sub {
        my @tokens = $tokenizer->encode("The quick brown fox jumps over the lazy dog");

        my %thread_times;

        for my $threads (1, 2, 4) {
            my $thread_inf = Lugh::Inference->new(
                model => $model,
                n_threads => $threads,
                backend => 'CPU',  # Force CPU for thread scaling test
            );

            my $ms = benchmark("threads_$threads", $BENCH_ITERS, sub {
                my @logits = $thread_inf->forward_simple(\@tokens);
            });

            $thread_times{$threads} = $ms;
            diag("$threads threads: ${ms}ms");
        }

        # More threads should generally be same or faster
        ok($thread_times{2} <= $thread_times{1} * 1.5,
           "2 threads not slower than 1 thread");
        ok($thread_times{4} <= $thread_times{1} * 1.5,
           "4 threads not slower than 1 thread");

        # Calculate speedups
        my $speedup_2 = $thread_times{1} / $thread_times{2};
        my $speedup_4 = $thread_times{1} / $thread_times{4};
        diag("Speedup: 2 threads=${speedup_2}x, 4 threads=${speedup_4}x");
    };

    # ============================================================================
    # Section H: Model Loading Time
    # ============================================================================

    subtest 'Model Loading Time' => sub {
        # This tests cold load time
        my $load_ms = benchmark("model_load", 3, sub {
            my $m = Lugh::Model->new(model => $model_file);
        });

        diag("Model load time: ${load_ms}ms");
        ok($load_ms > 0, "Model loads in measurable time");

        # Model loading should complete in reasonable time
        ok($load_ms < 10000, "Model loads in under 10 seconds");
    };

    # ============================================================================
    # Section I: Sampling Performance
    # ============================================================================

    subtest 'Sampling Performance' => sub {
        my @tokens = $tokenizer->encode("Hello world");
        my @logits = $inference->forward_simple(\@tokens);

        # Top-p sampling
        my $topp_ms = benchmark("sample_top_p", $BENCH_ITERS * 10, sub {
            my $token = $inference->sample_top_p(\@logits, temperature => 0.8, top_p => 0.9);
        });
        ok($topp_ms > 0, "Top-p sampling: ${topp_ms}ms");

        # Top-k sampling
        my $topk_ms = benchmark("sample_top_k", $BENCH_ITERS * 10, sub {
            my $token = $inference->sample_top_k(\@logits, top_k => 40);
        });
        ok($topk_ms > 0, "Top-k sampling: ${topk_ms}ms");

        diag("Sampling: top_p=${topp_ms}ms, top_k=${topk_ms}ms");

        # Sampling should be fast relative to forward pass
        my $forward_ms = benchmark("forward_ref", $BENCH_ITERS, sub {
            my @l = $inference->forward_simple(\@tokens);
        });

        my $sampling_overhead = ($topp_ms + $topk_ms) / 2;
        my $overhead_pct = 100 * $sampling_overhead / $forward_ms;
        diag("Sampling overhead: ${overhead_pct}% of forward time");

        ok($sampling_overhead < $forward_ms,
           "Sampling faster than forward pass");
    };

    # ============================================================================
    # Section J: Summary Statistics
    # ============================================================================

    subtest 'Performance Summary' => sub {
        my @tokens = $tokenizer->encode("The quick brown fox");

        # Collect comprehensive timings
        my %timings;

        $timings{encode} = benchmark("summary_encode", $BENCH_ITERS * 5, sub {
            my @t = $tokenizer->encode("The quick brown fox");
        });

        $timings{forward} = benchmark("summary_forward", $BENCH_ITERS, sub {
            my @l = $inference->forward_simple(\@tokens);
        });

        my $cache = $inference->create_kv_cache();
        $cache->clear();
        $inference->forward_cache($cache, \@tokens);

        $timings{decode} = benchmark("summary_decode", $BENCH_ITERS * 3, sub {
            my @l = $inference->forward_cache($cache, [$tokenizer->bos_id]);
        });

        my @logits = $inference->forward_simple(\@tokens);
        $timings{sample} = benchmark("summary_sample", $BENCH_ITERS * 10, sub {
            my $t = $inference->sample_top_p(\@logits, temperature => 0.8);
        });

        diag("\n=== Performance Summary ===");
        diag("Encode:  $timings{encode}ms");
        diag("Forward: $timings{forward}ms");
        diag("Decode:  $timings{decode}ms");
        diag("Sample:  $timings{sample}ms");

        # Calculate tokens per second estimate
        my $token_count = scalar @tokens;
        my $prefill_tps = 1000 * $token_count / $timings{forward};
        my $decode_tps = 1000 / $timings{decode};

        diag("Estimated prefill: ${prefill_tps} tok/s");
        diag("Estimated decode:  ${decode_tps} tok/s");

        # All operations should complete
        ok($timings{encode} > 0, 'Encode timing recorded');
        ok($timings{forward} > 0, 'Forward timing recorded');
        ok($timings{decode} > 0, 'Decode timing recorded');
        ok($timings{sample} > 0, 'Sample timing recorded');

        # Print baseline commands for future runs
        diag("\nTo set baselines for regression testing, run:");
        diag("  export LUGH_BASELINE_FORWARD_MS=$timings{forward}");
        diag("  export LUGH_BASELINE_DECODE_MS=$timings{decode}");
        diag("  export LUGH_BASELINE_TOKENIZE_MS=$timings{encode}");
    };
}

done_testing();
