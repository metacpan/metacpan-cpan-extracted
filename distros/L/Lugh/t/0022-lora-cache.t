#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

# Test LoRA integration with forward_cache

use_ok('Lugh');
use_ok('Lugh::LoRA');

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

my $test_model = "$Bin/data/test-model.gguf";
my $lora_file = "$Bin/data/test-lora.gguf";

SKIP: {
    skip "Test model not found", 22 unless -f $test_model && -f $lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    ok($model, "Test model loaded");
    diag("Model: " . $model->architecture);
    
    my $inf = Lugh::Inference->new(model => $model);
    ok($inf, "Inference context created");
    
    my $lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    ok($lora, "LoRA adapter loaded");
    diag("LoRA weights: " . $lora->n_weights . ", alpha: " . $lora->alpha);
    
    my $cache = $inf->create_kv_cache();
    ok($cache, "KV cache created");
    
    my @tokens = (1, 2, 3);
    diag("\n=== Testing forward_cache ===");
    diag("Input tokens: [@tokens]");
    
    my @logits1 = $inf->forward_cache($cache, \@tokens);
    ok(@logits1 > 0, "forward_cache (positional) returns logits");
    diag("Positional call returned " . scalar(@logits1) . " logits");
    
    $cache->clear();
    is($cache->n_cached, 0, "Cache cleared");
    
    @logits1 = $inf->forward_cache(cache => $cache, tokens => \@tokens);
    ok(@logits1 > 0, "forward_cache (named) returns logits");
    diag("Named call returned " . scalar(@logits1) . " logits");
    
    $cache->clear();
    
    diag("\n=== Testing with LoRA ===");
    my @logits_lora = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    ok(@logits_lora > 0, "forward_cache with LoRA returns logits");
    is(scalar(@logits_lora), scalar(@logits1), "LoRA output has same length");
    diag("LoRA call returned " . scalar(@logits_lora) . " logits");
    
    $cache->clear();
    
    diag("\n=== Testing scale=0 (should match baseline) ===");
    $lora->scale(0);
    my @logits_zero = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    ok(@logits_zero > 0, "forward_cache with scale=0 succeeds");
    
    $cache->clear();
    my @baseline = $inf->forward_cache(cache => $cache, tokens => \@tokens);
    
    my $match_count = 0;
    for my $i (0..$#baseline) {
        $match_count++ if abs($logits_zero[$i] - $baseline[$i]) < 0.001;
    }
    my $match_pct = $match_count / scalar(@baseline) * 100;
    ok($match_pct > 99, "scale=0 produces near-baseline output ($match_pct% match)");
    diag("Baseline match: $match_pct%");
    
    $lora->scale(1);
    
    diag("\n=== Testing incremental decoding with LoRA ===");
    $cache->clear();
    my @prompt_tokens = (1, 2);
    diag("Step 1: tokens [@prompt_tokens]");
    my @first_logits = $inf->forward_cache(cache => $cache, tokens => \@prompt_tokens, lora => $lora);
    ok(@first_logits > 0, "First incremental call with LoRA succeeds");
    is($cache->n_cached, 2, "Cache has 2 tokens");
    
    my @next_tokens = (3);
    diag("Step 2: tokens [@next_tokens]");
    my @next_logits = $inf->forward_cache(cache => $cache, tokens => \@next_tokens, lora => $lora);
    ok(@next_logits > 0, "Second incremental call with LoRA succeeds");
    is($cache->n_cached, 3, "Cache has 3 tokens");
    
    my @more_tokens = (4, 5);
    diag("Step 3: tokens [@more_tokens]");
    my @more_logits = $inf->forward_cache(cache => $cache, tokens => \@more_tokens, lora => $lora);
    ok(@more_logits > 0, "Third incremental call with LoRA succeeds");
    is($cache->n_cached, 5, "Cache has 5 tokens");
    
    diag("\n=== Testing LoRA scale effects ===");
    $cache->clear();
    
    $lora->scale(0.5);
    my @half_logits = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    ok(@half_logits > 0, "forward_cache with scale=0.5 succeeds");
    
    $cache->clear();
    $lora->scale(2.0);
    my @double_logits = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    ok(@double_logits > 0, "forward_cache with scale=2.0 succeeds");
    
    my ($max_base, $max_half, $max_double) = (0, 0, 0);
    for my $i (0..$#baseline) {
        $max_base = abs($baseline[$i]) if abs($baseline[$i]) > $max_base;
        $max_half = abs($half_logits[$i]) if abs($half_logits[$i]) > $max_half;
        $max_double = abs($double_logits[$i]) if abs($double_logits[$i]) > $max_double;
    }
    diag(sprintf("Max logit - baseline: %.2f, scale=0.5: %.2f, scale=2.0: %.2f", 
                 $max_base, $max_half, $max_double));
    
    $lora->scale(1);
    diag("\nGGUF LoRA + KV cache integration complete!");
}

# Test SafeTensors LoRA with forward_cache
my $st_lora_file = "$Bin/data/test-lora.safetensors";

SKIP: {
    skip "SafeTensors test files not found", 10 unless -f $test_model && -f $st_lora_file;
    
    diag("\n=== Testing SafeTensors LoRA with KV cache ===");
    
    my $model = Lugh::Model->new(model => $test_model);
    my $inf = Lugh::Inference->new(model => $model);
    
    my $lora = Lugh::LoRA->new(model => $model, file => $st_lora_file);
    ok($lora, "SafeTensors LoRA loaded");
    is($lora->format, 'safetensors', "Format is safetensors");
    
    my $cache = $inf->create_kv_cache();
    my @tokens = (1, 2, 3);
    
    # Baseline
    my @baseline = $inf->forward_cache($cache, \@tokens);
    ok(@baseline > 0, "Baseline forward_cache succeeds");
    
    # With SafeTensors LoRA
    $cache->clear();
    my @logits_lora = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    ok(@logits_lora > 0, "forward_cache with SafeTensors LoRA succeeds");
    is(scalar(@logits_lora), scalar(@baseline), "Output has correct length");
    
    # Scale=0 should match baseline
    $cache->clear();
    $lora->scale(0);
    my @logits_zero = $inf->forward_cache(cache => $cache, tokens => \@tokens, lora => $lora);
    
    $cache->clear();
    my @base2 = $inf->forward_cache($cache, \@tokens);
    
    my $match = 0;
    for my $i (0..$#base2) {
        $match++ if abs($logits_zero[$i] - $base2[$i]) < 0.001;
    }
    my $pct = $match / scalar(@base2) * 100;
    ok($pct > 99, "scale=0 matches baseline: $pct%");
    
    # Incremental decoding with SafeTensors LoRA
    $lora->scale(1);
    $cache->clear();
    my @first = $inf->forward_cache(cache => $cache, tokens => [1, 2], lora => $lora);
    ok(@first > 0, "Incremental step 1 succeeds");
    my @second = $inf->forward_cache(cache => $cache, tokens => [3], lora => $lora);
    ok(@second > 0, "Incremental step 2 succeeds");
    is($cache->n_cached, 3, "Cache has 3 tokens");
    
    diag("SafeTensors LoRA + KV cache integration complete!");
}

# Text output tests - verify LoRA actually changes predictions
SKIP: {
    skip "Test files not available for text tests", 8 
        unless -f $test_model && -f $lora_file && -f $st_lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    my $tok = Lugh::Tokenizer->new(model => $model);
    my $inf = Lugh::Inference->new(model => $model);
    my $gguf_lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    my $cache = $inf->create_kv_cache();
    
    diag("\n=== Text Output Tests for forward_cache ===");
    
    # Test with "The quick brown"
    my @prompt = $tok->encode("The quick brown");
    diag("Prompt: \"The quick brown\"");
    
    # Baseline prediction
    $cache->clear();
    my @base_logits = $inf->forward_cache($cache, \@prompt);
    my @top_base = get_top_predictions(\@base_logits, $tok, 3);
    my $base_text = $top_base[0]{text};
    
    # LoRA prediction
    $gguf_lora->scale(1.0);
    $cache->clear();
    my @lora_logits = $inf->forward_cache(cache => $cache, tokens => \@prompt, lora => $gguf_lora);
    my @top_lora = get_top_predictions(\@lora_logits, $tok, 3);
    my $lora_text = $top_lora[0]{text};
    
    diag("  Baseline: \"$base_text\"  LoRA: \"$lora_text\"");
    
    # Check if text changed OR ranking changed
    my $text_changed = $base_text ne $lora_text;
    my $rank_changed = 0;
    for my $i (0..2) {
        $rank_changed++ if $top_base[$i]{id} != $top_lora[$i]{id};
    }
    diag("  Ranking changes: $rank_changed of 3");
    
    # LoRA should change text prediction
    ok($text_changed, "LoRA CHANGES text: \"$base_text\" -> \"$lora_text\"");
    
    # LoRA should change ranking 
    ok($rank_changed > 0, "LoRA changes top 3 ranking ($rank_changed positions differ)");
    
    # scale=0 must produce identical text
    $gguf_lora->scale(0);
    $cache->clear();
    my @zero_logits = $inf->forward_cache(cache => $cache, tokens => \@prompt, lora => $gguf_lora);
    my @top_zero = get_top_predictions(\@zero_logits, $tok, 1);
    is($top_zero[0]{text}, $base_text, 
       "scale=0 produces identical text: \"$top_zero[0]{text}\"");
    
    # Test incremental generation shows text
    diag("\n--- Incremental generation with cache ---");
    $gguf_lora->scale(1.0);
    $cache->clear();
    
    my @prompt2 = $tok->encode("Once upon");
    my @gen_texts;
    
    my @logits = $inf->forward_cache(cache => $cache, tokens => \@prompt2, lora => $gguf_lora);
    my @top = get_top_predictions(\@logits, $tok, 1);
    push @gen_texts, $top[0]{text};
    
    # Generate 2 more tokens
    for (1..2) {
        @logits = $inf->forward_cache(cache => $cache, tokens => [$top[0]{id}], lora => $gguf_lora);
        @top = get_top_predictions(\@logits, $tok, 1);
        push @gen_texts, $top[0]{text};
    }
    
    diag("  Generated: \"Once upon\" -> \"" . join("", @gen_texts) . "\"");
    ok(scalar(@gen_texts) == 3, "Generated 3 tokens incrementally");
    ok(length(join("", @gen_texts)) > 0, "Generated non-empty text");
    
    # Verify logits changed throughout vocab
    my $changed = 0;
    for my $i (0..$#base_logits) {
        $changed++ if abs($base_logits[$i] - $lora_logits[$i]) > 0.0001;
    }
    my $pct = 100 * $changed / scalar(@base_logits);
    ok($pct > 50, sprintf("LoRA modifies %.1f%% of all %d logits", $pct, scalar(@base_logits)));
    
    # Verify different prompts also work
    my @prompt3 = $tok->encode("Hello world");
    $cache->clear();
    my @base3 = $inf->forward_cache($cache, \@prompt3);
    $cache->clear();
    my @lora3 = $inf->forward_cache(cache => $cache, tokens => \@prompt3, lora => $gguf_lora);
    my @top_base3 = get_top_predictions(\@base3, $tok, 3);
    my @top_lora3 = get_top_predictions(\@lora3, $tok, 3);
    
    my $rank3_changed = 0;
    for my $i (0..2) {
        $rank3_changed++ if $top_base3[$i]{id} != $top_lora3[$i]{id};
    }
    ok($rank3_changed > 0 || $top_base3[0]{text} ne $top_lora3[0]{text},
       "LoRA affects \"Hello world\" prediction (rank_changes=$rank3_changed)");
    
    diag("\n=== Cache text output tests complete ===\n");
}

done_testing();
