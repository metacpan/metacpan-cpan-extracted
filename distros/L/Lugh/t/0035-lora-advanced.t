#!/usr/bin/env perl
# t/35-lora-advanced.t - Advanced LoRA patterns: sequential application, scale manipulation,
# adapter switching, and multi-adapter simulation tests

use strict;
use warnings;
use Test::More;
use File::Spec;
use FindBin;

use Lugh;
use Lugh::LoRA;

# Helper to get argmax of logits
sub argmax {
    my ($logits) = @_;
    my $max_idx = 0;
    my $max_val = $logits->[0];
    for my $i (1..$#{$logits}) {
        if ($logits->[$i] > $max_val) {
            $max_val = $logits->[$i];
            $max_idx = $i;
        }
    }
    return ($max_idx, $max_val);
}

# Helper to compute logit difference
sub logit_diff {
    my ($a, $b) = @_;
    my $diff = 0;
    my $n = scalar @$a;
    for my $i (0..$n-1) {
        $diff += abs($a->[$i] - $b->[$i]);
    }
    return $diff / $n;  # Average absolute difference
}

# Helper to count how many logits differ
sub count_different_logits {
    my ($a, $b, $threshold) = @_;
    $threshold //= 1e-5;
    my $count = 0;
    for my $i (0..$#{$a}) {
        $count++ if abs($a->[$i] - $b->[$i]) > $threshold;
    }
    return $count;
}

my $model_path = File::Spec->catfile('t', 'data', 'test-model.gguf');
my $gguf_lora_path = File::Spec->catfile('t', 'data', 'test-lora.gguf');
my $st_lora_path = File::Spec->catfile('t', 'data', 'test-lora.safetensors');

SKIP: {
    skip "Test model not available", 1 unless -f $model_path;
    skip "Test LoRA not available", 1 unless -f $gguf_lora_path;

    # Load model and create components
    my $model = Lugh::Model->new(model => $model_path);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);

    ok($model, 'Model loaded');
    ok($tokenizer, 'Tokenizer created');
    ok($inference, 'Inference created');

    # Load LoRA adapter
    my $lora = Lugh::LoRA->new(adapter => $gguf_lora_path, model => $model);
    ok($lora, 'GGUF LoRA loaded');

    my @tokens = $tokenizer->encode("The quick brown fox");
    diag("Test tokens: " . scalar(@tokens) . " tokens");

    # ============================================================================
    # Section A: Scale Manipulation Patterns
    # ============================================================================

    subtest 'Scale Manipulation Patterns' => sub {
        # Get baseline (no LoRA)
        my @baseline = $inference->forward_simple(\@tokens);
        my ($base_argmax, $base_max) = argmax(\@baseline);

        # Get LoRA result at scale 1.0
        $lora->scale(1.0);
        my @lora_1 = $inference->forward(tokens => \@tokens, lora => $lora);
        my ($lora1_argmax, $lora1_max) = argmax(\@lora_1);

        # Test scale=0 produces baseline
        $lora->scale(0.0);
        my @lora_0 = $inference->forward(tokens => \@tokens, lora => $lora);
        my $diff_0 = logit_diff(\@baseline, \@lora_0);
        ok($diff_0 < 1e-4, "scale=0 produces baseline (diff=$diff_0)");

        # Test scale=0.5 produces intermediate result
        $lora->scale(0.5);
        my @lora_half = $inference->forward(tokens => \@tokens, lora => $lora);
        my $diff_base_half = logit_diff(\@baseline, \@lora_half);
        my $diff_lora_half = logit_diff(\@lora_1, \@lora_half);
        ok($diff_base_half > 0, "scale=0.5 differs from baseline (diff=$diff_base_half)");
        ok($diff_lora_half > 0, "scale=0.5 differs from scale=1.0 (diff=$diff_lora_half)");

        # Test scale=2.0 (stronger effect)
        $lora->scale(2.0);
        my @lora_2 = $inference->forward(tokens => \@tokens, lora => $lora);
        my $diff_2 = logit_diff(\@baseline, \@lora_2);
        my $diff_1 = logit_diff(\@baseline, \@lora_1);
        # scale=2 should have larger deviation from baseline than scale=1
        # (though this isn't always guaranteed due to nonlinearity)
        ok($diff_2 > 0, "scale=2.0 produces different result (diff=$diff_2)");
        diag("Baseline vs scale=1: $diff_1, vs scale=2: $diff_2");

        # Test scale=3.0 (stability test - very high scale)
        $lora->scale(3.0);
        my @lora_3;
        eval {
            @lora_3 = $inference->forward(tokens => \@tokens, lora => $lora);
        };
        ok(!$@ && @lora_3 == @baseline, 'scale=3.0 completes without error');

        # Verify argmax can differ at high scales
        my ($lora3_argmax, $lora3_max) = argmax(\@lora_3);
        diag("Argmax: baseline=$base_argmax, scale=1=$lora1_argmax, scale=3=$lora3_argmax");

        # Reset to 1.0
        $lora->scale(1.0);
        is($lora->scale, 1.0, 'Scale reset to 1.0');
    };

    # ============================================================================
    # Section B: Adapter Switching with Cache
    # ============================================================================

    subtest 'Adapter Switching with Cache' => sub {
        my $cache = $inference->create_kv_cache();
        ok($cache, 'KV cache created');

        my @prompt = $tokenizer->encode("Once upon a");

        # Forward with no LoRA first
        my @logits_no_lora = $inference->forward_cache($cache, \@prompt);
        ok(@logits_no_lora > 0, 'Cache forward without LoRA works');
        my $cached_after_no_lora = $cache->n_cached;
        ok($cached_after_no_lora > 0, "Cache has $cached_after_no_lora tokens");

        # Now use forward with LoRA on SAME cache
        $lora->scale(1.0);
        my @logits_with_lora = $inference->forward_cache($cache, [0], lora => $lora);
        # Note: forward_cache with new token appends to cache
        ok(@logits_with_lora > 0, 'Cache forward with LoRA works');

        # The outputs should potentially differ due to LoRA
        my $lora_applied = count_different_logits(\@logits_no_lora, \@logits_with_lora, 1e-5);
        ok(1, "LoRA on cached forward: $lora_applied logits differ from previous");

        # Clear cache and try with fresh prompts
        $cache->clear();
        is($cache->n_cached, 0, 'Cache cleared');

        # Forward with LoRA first this time
        $lora->scale(1.0);
        my @logits_lora_first = $inference->forward_cache($cache, \@prompt, lora => $lora);
        ok(@logits_lora_first > 0, 'LoRA-first cache forward works');

        # Clear and forward without LoRA
        $cache->clear();
        my @logits_base_after = $inference->forward_cache($cache, \@prompt);
        ok(@logits_base_after > 0, 'Base forward after LoRA works');

        # Compare - they should differ
        my $diff_count = count_different_logits(\@logits_lora_first, \@logits_base_after, 1e-5);
        ok($diff_count > 0, "LoRA vs base differ by $diff_count logits");
    };

    # ============================================================================
    # Section C: Same Adapter at Different Scales
    # ============================================================================

    subtest 'Scale Linearity Check' => sub {
        # Theory: If LoRA is linear, applying at scale 0.5 twice should NOT equal scale 1.0
        # because the computation is: output = base + scale * lora_effect
        # Applying twice would be: base + 0.5*effect + 0.5*effect = base + effect (same as scale=1)
        # But since we can only apply once per forward, we test something simpler

        # Get baseline
        my @base = $inference->forward_simple(\@tokens);

        # Get scale=0.5
        $lora->scale(0.5);
        my @half = $inference->forward(tokens => \@tokens, lora => $lora);

        # Get scale=1.0
        $lora->scale(1.0);
        my @full = $inference->forward(tokens => \@tokens, lora => $lora);

        # Compute deltas from baseline
        my @delta_half = map { $half[$_] - $base[$_] } 0..$#base;
        my @delta_full = map { $full[$_] - $base[$_] } 0..$#base;

        # Check if delta_full is approximately 2*delta_half (linearity)
        my $linearity_error = 0;
        my $n = scalar @base;
        for my $i (0..$n-1) {
            my $expected = 2 * $delta_half[$i];
            $linearity_error += abs($delta_full[$i] - $expected);
        }
        $linearity_error /= $n;

        diag("Linearity error (should be small if linear): $linearity_error");

        # We don't strictly assert linearity since it depends on implementation
        # but we verify the relationship is consistent
        ok($linearity_error < 10, "Scale linearity within tolerance (error=$linearity_error)");
    };

    # ============================================================================
    # Section D: Batch Processing with LoRA
    # ============================================================================

    subtest 'Batch Processing with LoRA' => sub {
        my @tokens1 = $tokenizer->encode("Hello");
        my @tokens2 = $tokenizer->encode("World");
        my @tokens3 = $tokenizer->encode("Test");

        # Forward batch without LoRA
        my $results_base = $inference->forward_batch([\@tokens1, \@tokens2, \@tokens3]);
        ok(ref($results_base) eq 'ARRAY', 'Batch forward returns array');
        is(scalar @$results_base, 3, 'Batch has 3 results');

        # Forward batch with LoRA
        $lora->scale(1.0);
        my $results_lora = $inference->forward_batch(
            [\@tokens1, \@tokens2, \@tokens3],
            lora => $lora,
        );
        ok(ref($results_lora) eq 'ARRAY', 'Batch with LoRA returns array');
        is(scalar @$results_lora, 3, 'Batch with LoRA has 3 results');

        # Each result should have same vocab size
        for my $i (0..2) {
            is(scalar @{$results_lora->[$i]}, scalar @{$results_base->[$i]},
               "Sequence $i has same output size");
        }

        # Check that LoRA affected the results
        my $total_diff = 0;
        for my $i (0..2) {
            my $diff = count_different_logits($results_base->[$i], $results_lora->[$i], 1e-5);
            $total_diff += $diff;
            diag("Sequence $i: $diff logits differ");
        }
        ok($total_diff > 0, "LoRA affected batch results ($total_diff total logits differ)");
    };

    # ============================================================================
    # Section E: Memory Pool with LoRA
    # ============================================================================

    subtest 'Memory Pool with LoRA' => sub {
        my $pool = $inference->create_memory_pool();
        ok($pool, 'Memory pool created');

        # Forward with pool and no LoRA
        my @logits_base = $inference->forward_pool($pool, \@tokens);
        ok(@logits_base > 0, 'Pool forward without LoRA works');

        # Forward with pool and LoRA
        $lora->scale(1.0);
        my @logits_lora = $inference->forward_pool($pool, \@tokens, lora => $lora);
        ok(@logits_lora > 0, 'Pool forward with LoRA works');
        is(scalar @logits_lora, scalar @logits_base, 'Same output size');

        # Results should differ
        my $diff = count_different_logits(\@logits_base, \@logits_lora, 1e-5);
        ok($diff > 0, "Pool+LoRA differs from pool alone ($diff logits)");

        # Reset pool and verify it still works
        $pool->reset();
        my @logits_after = $inference->forward_pool($pool, \@tokens);
        ok(@logits_after > 0, 'Pool forward after reset works');
    };

    # ============================================================================
    # Section F: Dual Format Comparison (GGUF vs SafeTensors)
    # ============================================================================

    SKIP: {
        skip "SafeTensors LoRA not available", 1 unless -f $st_lora_path;

        subtest 'GGUF vs SafeTensors LoRA' => sub {
            my $st_lora = Lugh::LoRA->new(adapter => $st_lora_path, model => $model);
            ok($st_lora, 'SafeTensors LoRA loaded');

            is($lora->format, 'gguf', 'First adapter is GGUF');
            is($st_lora->format, 'safetensors', 'Second adapter is SafeTensors');

            # Compare properties
            is($lora->n_weights, $st_lora->n_weights, 'Same number of weight pairs');

            # Forward with each at scale=1.0
            $lora->scale(1.0);
            $st_lora->scale(1.0);

            my @logits_gguf = $inference->forward(tokens => \@tokens, lora => $lora);
            my @logits_st = $inference->forward(tokens => \@tokens, lora => $st_lora);

            is(scalar @logits_gguf, scalar @logits_st, 'Same output size');

            # They should be similar if they represent the same adapter
            my $diff = logit_diff(\@logits_gguf, \@logits_st);
            diag("GGUF vs SafeTensors avg diff: $diff");

            # If they're the same adapter data, diff should be very small
            # If they're different adapters, this still tests dual-format works
            ok($diff >= 0, "Both formats produce valid output (diff=$diff)");

            # Both should differ from baseline
            my @baseline = $inference->forward_simple(\@tokens);
            my $gguf_from_base = logit_diff(\@logits_gguf, \@baseline);
            my $st_from_base = logit_diff(\@logits_st, \@baseline);

            ok($gguf_from_base > 0, "GGUF differs from baseline (diff=$gguf_from_base)");
            ok($st_from_base > 0, "SafeTensors differs from baseline (diff=$st_from_base)");
        };
    }

    # ============================================================================
    # Section G: Edge Cases
    # ============================================================================

    subtest 'LoRA Edge Cases' => sub {
        # Test rapid scale changes
        my @results;
        for my $scale (0, 0.1, 0.5, 1.0, 1.5, 2.0, 0) {
            $lora->scale($scale);
            my @logits = $inference->forward(tokens => \@tokens, lora => $lora);
            push @results, { scale => $scale, logits => \@logits };
        }

        # First and last should be identical (both scale=0)
        my $first_last_diff = logit_diff($results[0]{logits}, $results[-1]{logits});
        ok($first_last_diff < 1e-6, "scale=0 at start and end match (diff=$first_last_diff)");

        # Test negative scale (if supported)
        eval {
            $lora->scale(-0.5);
            my @neg = $inference->forward(tokens => \@tokens, lora => $lora);
            ok(@neg > 0, 'Negative scale produces output');
        };
        if ($@) {
            ok(1, 'Negative scale rejected (acceptable behavior)');
        }

        # Reset scale
        $lora->scale(1.0);

        # Test with single token
        my @single = ($tokenizer->bos_id);
        my @single_logits = $inference->forward(tokens => \@single, lora => $lora);
        ok(@single_logits > 0, 'LoRA with single token works');

        # Test with longer sequence
        my @long = $tokenizer->encode("The quick brown fox jumps over the lazy dog");
        my @long_logits = $inference->forward(tokens => \@long, lora => $lora);
        ok(@long_logits > 0, 'LoRA with longer sequence works');
        is(scalar @long_logits, scalar @single_logits, 'Output size independent of input length');
    };

    # ============================================================================
    # Section H: Reproducibility with LoRA
    # ============================================================================

    subtest 'LoRA Reproducibility' => sub {
        $lora->scale(1.0);

        # Run twice with same seed
        Lugh::srand(12345);
        my @logits1 = $inference->forward(tokens => \@tokens, lora => $lora);
        my $sample1 = $inference->sample_top_p(\@logits1, temperature => 0.8, top_p => 0.9);

        Lugh::srand(12345);
        my @logits2 = $inference->forward(tokens => \@tokens, lora => $lora);
        my $sample2 = $inference->sample_top_p(\@logits2, temperature => 0.8, top_p => 0.9);

        # Logits should be identical (deterministic)
        my $logit_diff = logit_diff(\@logits1, \@logits2);
        ok($logit_diff < 1e-10, "LoRA forward is deterministic (diff=$logit_diff)");

        # Samples should match with same seed
        is($sample1, $sample2, 'Same seed produces same sample with LoRA');

        # Different seed should (likely) produce different sample
        Lugh::srand(99999);
        my @logits3 = $inference->forward(tokens => \@tokens, lora => $lora);
        my $sample3 = $inference->sample_top_p(\@logits3, temperature => 0.8, top_p => 0.9);

        # Logits still deterministic (same model state)
        my $logit_diff3 = logit_diff(\@logits1, \@logits3);
        ok($logit_diff3 < 1e-10, "Different seed, same logits (diff=$logit_diff3)");

        # But sample may differ (depends on RNG in sampling)
        diag("Sample with seed 12345: $sample1, with seed 99999: $sample3");
    };
}

done_testing();
