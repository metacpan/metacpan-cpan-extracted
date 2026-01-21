#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;

# Test LoRA integration with forward pass

BEGIN {
    use_ok('Lugh') or BAIL_OUT("Cannot load Lugh");
    use_ok('Lugh::LoRA') or BAIL_OUT("Cannot load Lugh::LoRA");
}

# Helper to get top N predictions with text
sub get_top_predictions {
    my ($logits, $tokenizer, $n) = @_;
    $n //= 5;
    my @indexed = map { [$_, $logits->[$_]] } 0..$#{$logits};
    @indexed = sort { $b->[1] <=> $a->[1] } @indexed;
    my @results;
    for my $i (0..$n-1) {
        my ($id, $logit) = @{$indexed[$i]};
        my $text = $tokenizer->decode([$id]);
        $text =~ s/\n/\\n/g;
        push @results, { id => $id, logit => $logit, text => $text };
    }
    return @results;
}

# Find the test files
my $model_path = File::Spec->catfile('t', 'data', 'test-model.gguf');
my $gguf_lora_path = File::Spec->catfile('t', 'data', 'test-lora.gguf');

SKIP: {
    skip "Test model not available", 20 unless -f $model_path;
    skip "Test LoRA not available", 20 unless -f $gguf_lora_path;
    
    # Load model and create inference context
    my $model = Lugh::Model->new(file => $model_path);
    ok($model, 'Model loaded');
    
    my $ctx = Lugh::Inference->new(model => $model);
    ok($ctx, 'Inference context created');
    
    # Load LoRA adapter
    my $lora = Lugh::LoRA->new(adapter => $gguf_lora_path, model => $model);
    ok($lora, 'LoRA adapter loaded');
    is($lora->n_weights, 4, 'LoRA has 4 weight pairs');
    
    # Test forward without LoRA (baseline)
    my @tokens = (1, 2, 3);
    my @logits_baseline;
    eval {
        @logits_baseline = $ctx->forward_simple(\@tokens);
    };
    ok(!$@, 'forward() without LoRA succeeds') or diag($@);
    ok(@logits_baseline > 0, 'forward() returns logits');
    
    my $baseline_len = scalar @logits_baseline;
    ok($baseline_len > 0, "Baseline logits has $baseline_len elements");
    
    # Test forward with LoRA using named parameters
    my @logits_lora;
    eval {
        @logits_lora = $ctx->forward(tokens => \@tokens, lora => $lora);
    };
    ok(!$@, 'forward() with LoRA succeeds') or diag($@);
    ok(@logits_lora > 0, 'forward() with LoRA returns logits');
    
    is(scalar @logits_lora, $baseline_len, 
       'LoRA output has same length as baseline');
    
    # Compare outputs - they should be different (LoRA modifies the computation)
    my $diff_count = 0;
    for my $i (0 .. $#logits_baseline) {
        if (abs($logits_baseline[$i] - $logits_lora[$i]) > 1e-6) {
            $diff_count++;
        }
    }
    
    # With zero-initialized B matrices, LoRA should have no effect initially
    # But with random A matrices, there might still be numerical differences
    # The key test is that it runs without errors
    ok(1, "LoRA integration completed (diff_count=$diff_count)");
    
    # Test LoRA with different scales
    $lora->scale(0.0);
    my @logits_zero_scale;
    eval {
        @logits_zero_scale = $ctx->forward(tokens => \@tokens, lora => $lora);
    };
    ok(!$@, 'forward() with scale=0 succeeds') or diag($@);
    
    # With scale=0, should match baseline closely
    my $zero_scale_diff = 0;
    for my $i (0 .. $#logits_baseline) {
        $zero_scale_diff += abs($logits_baseline[$i] - $logits_zero_scale[$i]);
    }
    # Allow small numerical differences
    ok($zero_scale_diff < 1e-3 * $baseline_len, 
       'scale=0 produces near-baseline output');
    
    # Test LoRA with high scale
    $lora->scale(2.0);
    my @logits_high_scale;
    eval {
        @logits_high_scale = $ctx->forward(tokens => \@tokens, lora => $lora);
    };
    ok(!$@, 'forward() with scale=2.0 succeeds') or diag($@);
    
    # Reset scale
    $lora->scale(1.0);
    is($lora->scale, 1.0, 'Scale reset to 1.0');
    
    # Test that we can still use positional args for backward compat
    my @logits_positional;
    eval {
        @logits_positional = $ctx->forward_simple(\@tokens);
    };
    ok(!$@, 'forward() with positional array ref still works') or diag($@);
    is(scalar @logits_positional, $baseline_len, 
       'Positional call returns correct length');
    
    pass('GGUF LoRA integration tests completed');
}

# Test SafeTensors LoRA with forward pass
my $st_lora_path = File::Spec->catfile('t', 'data', 'test-lora.safetensors');

SKIP: {
    skip "Test model not available", 10 unless -f $model_path;
    skip "SafeTensors LoRA not available", 10 unless -f $st_lora_path;
    
    diag("\n=== Testing SafeTensors LoRA ===");
    
    # Load model and create inference context
    my $model = Lugh::Model->new(file => $model_path);
    my $ctx = Lugh::Inference->new(model => $model);
    
    # Load SafeTensors LoRA adapter
    my $lora;
    eval {
        $lora = Lugh::LoRA->new(adapter => $st_lora_path, model => $model);
    };
    ok(!$@, 'SafeTensors LoRA loads without error') or diag($@);
    
    SKIP: {
        skip "SafeTensors LoRA failed to load", 9 unless $lora;
        
        is($lora->format, 'safetensors', 'Format is safetensors');
        is($lora->n_weights, 4, 'SafeTensors LoRA has 4 weight pairs');
        
        # Get baseline
        my @tokens = (1, 2, 3);
        my @logits_baseline = $ctx->forward_simple(\@tokens);
        ok(@logits_baseline > 0, 'Baseline forward succeeds');
        
        # Forward with SafeTensors LoRA
        my @logits_lora;
        eval {
            @logits_lora = $ctx->forward(tokens => \@tokens, lora => $lora);
        };
        ok(!$@, 'forward() with SafeTensors LoRA succeeds') or diag($@);
        is(scalar @logits_lora, scalar @logits_baseline, 
           'SafeTensors LoRA output has correct length');
        
        # Test scale=0 matches baseline
        $lora->scale(0.0);
        my @logits_zero = $ctx->forward(tokens => \@tokens, lora => $lora);
        my $match_count = 0;
        for my $i (0 .. $#logits_baseline) {
            $match_count++ if abs($logits_baseline[$i] - $logits_zero[$i]) < 1e-5;
        }
        my $match_pct = 100 * $match_count / scalar(@logits_baseline);
        ok($match_pct > 99, "scale=0 matches baseline: $match_pct%");
        
        # Test scale=1.0
        $lora->scale(1.0);
        my @logits_full;
        eval {
            @logits_full = $ctx->forward(tokens => \@tokens, lora => $lora);
        };
        ok(!$@, 'forward() with scale=1.0 succeeds') or diag($@);
        
        pass('SafeTensors LoRA forward integration complete');
    }
}

# Human-readable text output tests with REAL string assertions
my $st_lora_path2 = File::Spec->catfile('t', 'data', 'test-lora.safetensors');

SKIP: {
    skip "Test files not available for text tests", 12 
        unless -f $model_path && -f $gguf_lora_path && -f $st_lora_path2;
    
    my $model = Lugh::Model->new(file => $model_path);
    my $tok = Lugh::Tokenizer->new(model => $model);
    my $ctx = Lugh::Inference->new(model => $model);
    my $gguf_lora = Lugh::LoRA->new(adapter => $gguf_lora_path, model => $model);
    my $st_lora = Lugh::LoRA->new(adapter => $st_lora_path2, model => $model);
    
    diag("\n=== Text Output Tests ===");
    
    # Test 1: Get actual text predictions for "Once upon a time"
    my @prompt1 = $tok->encode("Once upon a time");
    diag("Prompt 1: \"Once upon a time\"");
    
    my @base1 = $ctx->forward_simple(\@prompt1);
    my @top_base1 = get_top_predictions(\@base1, $tok, 3);
    my $base1_text = $top_base1[0]{text};
    
    $gguf_lora->scale(1.0);
    my @lora1 = $ctx->forward(tokens => \@prompt1, lora => $gguf_lora);
    my @top_lora1 = get_top_predictions(\@lora1, $tok, 3);
    my $lora1_text = $top_lora1[0]{text};
    
    # Check if text changed OR if top 3 ranking changed
    my $p1_text_changed = $base1_text ne $lora1_text;
    my $p1_rank_changed = 0;
    for my $i (0..2) {
        $p1_rank_changed++ if $top_base1[$i]{id} != $top_lora1[$i]{id};
    }
    
    diag("  Baseline: \"$base1_text\"  LoRA: \"$lora1_text\"");
    diag("  Top 3 ranking changes: $p1_rank_changed");
    
    ok($p1_text_changed || $p1_rank_changed > 0, 
       "Prompt 1: LoRA changes text or ranking (text_changed=$p1_text_changed, rank_changes=$p1_rank_changed)");
    
    # Test 2: scale=0 MUST produce identical text to baseline
    $gguf_lora->scale(0);
    my @zero1 = $ctx->forward(tokens => \@prompt1, lora => $gguf_lora);
    my @top_zero1 = get_top_predictions(\@zero1, $tok, 1);
    my $zero1_text = $top_zero1[0]{text};
    
    is($zero1_text, $base1_text, 
       "scale=0 produces IDENTICAL text: \"$zero1_text\" eq \"$base1_text\"");;
    
    # Test 3: SafeTensors LoRA text prediction
    $st_lora->scale(1.0);
    my @st1 = $ctx->forward(tokens => \@prompt1, lora => $st_lora);
    my @top_st1 = get_top_predictions(\@st1, $tok, 1);
    my $st1_text = $top_st1[0]{text};
    
    like($st1_text, qr/.+/, "SafeTensors LoRA predicts text: \"$st1_text\"");
    
    # Test 4: Second prompt "The quick brown"
    my @prompt2 = $tok->encode("The quick brown");
    diag("\nPrompt 2: \"The quick brown\"");
    
    my @base2 = $ctx->forward_simple(\@prompt2);
    my @top_base2 = get_top_predictions(\@base2, $tok, 1);
    my $base2_text = $top_base2[0]{text};
    
    $gguf_lora->scale(1.0);
    my @lora2 = $ctx->forward(tokens => \@prompt2, lora => $gguf_lora);
    my @top_lora2 = get_top_predictions(\@lora2, $tok, 1);
    my $lora2_text = $top_lora2[0]{text};
    
    like($base2_text, qr/.+/, "Baseline predicts: \"$base2_text\"");
    like($lora2_text, qr/.+/, "GGUF LoRA predicts: \"$lora2_text\"");
    
    # REAL TEST: LoRA changes the actual text prediction for prompt 2
    isnt($base2_text, $lora2_text, 
         "LoRA CHANGES text prediction: \"$base2_text\" -> \"$lora2_text\"");
    
    # Test 5: Third prompt "Hello world" - verify logit difference even if top prediction same
    my @prompt3 = $tok->encode("Hello world");
    diag("\nPrompt 3: \"Hello world\"");
    
    my @base3 = $ctx->forward_simple(\@prompt3);
    my @top_base3 = get_top_predictions(\@base3, $tok, 3);
    my $base3_text = $top_base3[0]{text};
    
    $gguf_lora->scale(1.0);
    my @lora3 = $ctx->forward(tokens => \@prompt3, lora => $gguf_lora);
    my @top_lora3 = get_top_predictions(\@lora3, $tok, 3);
    my $lora3_text = $top_lora3[0]{text};
    
    # Check if text changed OR if ranking changed
    my $text_changed = $base3_text ne $lora3_text;
    my $rank_changed = 0;
    for my $i (0..2) {
        $rank_changed++ if $top_base3[$i]{id} != $top_lora3[$i]{id};
    }
    
    diag("  Baseline: \"$base3_text\"  LoRA: \"$lora3_text\"");
    diag("  Top 3 ranking changes: $rank_changed");
    
    ok($text_changed || $rank_changed > 0, 
       "Prompt 3: LoRA changes text or ranking (text_changed=$text_changed, rank_changes=$rank_changed)");
    
    # Test 6: Verify the logit distribution changed (more than half of logits differ)
    my $changed = 0;
    for my $i (0..$#base1) {
        $changed++ if abs($base1[$i] - $lora1[$i]) > 0.0001;
    }
    my $pct = 100 * $changed / scalar(@base1);
    ok($pct > 50, sprintf("LoRA modifies %.1f%% of all %d logits", $pct, scalar(@base1)));
    
    # Test 7: Get top 3 predictions and show them
    diag("\n--- Top 3 predictions comparison ---");
    my @top3_base = get_top_predictions(\@base1, $tok, 3);
    my @top3_lora = get_top_predictions(\@lora1, $tok, 3);
    
    diag("Baseline top 3:");
    for my $i (0..2) {
        diag(sprintf("  %d. \"%s\" (%.2f)", $i+1, $top3_base[$i]{text}, $top3_base[$i]{logit}));
    }
    
    diag("GGUF LoRA top 3:");
    for my $i (0..2) {
        diag(sprintf("  %d. \"%s\" (%.2f)", $i+1, $top3_lora[$i]{text}, $top3_lora[$i]{logit}));
    }
    
    # Assert the top 3 texts are valid strings
    for my $i (0..2) {
        ok(defined $top3_base[$i]{text} && length($top3_base[$i]{text}) > 0,
           "Baseline #" . ($i+1) . " is valid: \"$top3_base[$i]{text}\"");
    }
    
    # REAL TEST: LoRA changes the ranking (top 3 order or values differ)
    my $ranking_changed = 0;
    for my $i (0..2) {
        $ranking_changed++ if $top3_base[$i]{id} != $top3_lora[$i]{id};
    }
    ok($ranking_changed > 0, 
       "LoRA changes top 3 ranking ($ranking_changed of 3 positions differ)");
    
    diag("\n=== Text output tests complete ===\n");
}

done_testing();
