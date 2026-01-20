#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

# Test LoRA integration with forward_with_pool

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
    skip "Test model not found", 18 unless -f $test_model && -f $lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    ok($model, "Test model loaded");
    diag("Model: " . $model->architecture);
    
    my $inf = Lugh::Inference->new(model => $model);
    ok($inf, "Inference context created");
    
    my $lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    ok($lora, "LoRA adapter loaded");
    diag("LoRA weights: " . $lora->n_weights . ", alpha: " . $lora->alpha);
    
    my $pool = $inf->create_memory_pool();
    ok($pool, "Memory pool created");
    
    my @tokens = (1, 2, 3);
    diag("\n=== Testing forward_with_pool ===");
    diag("Input tokens: [@tokens]");
    
    # Test positional args (no LoRA)
    my @logits1 = $inf->forward_with_pool($pool, \@tokens);
    ok(@logits1 > 0, "forward_with_pool (positional) returns logits");
    diag("Positional call returned " . scalar(@logits1) . " logits");
    
    # Test named args (no LoRA)
    my @logits2 = $inf->forward_with_pool(pool => $pool, tokens => \@tokens);
    ok(@logits2 > 0, "forward_with_pool (named) returns logits");
    diag("Named call returned " . scalar(@logits2) . " logits");
    
    # Test with LoRA
    diag("\n=== Testing with LoRA ===");
    my @logits_lora = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@logits_lora > 0, "forward_with_pool with LoRA returns logits");
    is(scalar(@logits_lora), scalar(@logits1), "LoRA output has same length");
    diag("LoRA call returned " . scalar(@logits_lora) . " logits");
    
    # Test with scale=0 (should match baseline)
    diag("\n=== Testing scale=0 (should match baseline) ===");
    $lora->scale(0);
    my @logits_zero = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@logits_zero > 0, "forward_with_pool with scale=0 succeeds");
    
    my @baseline = $inf->forward_with_pool(pool => $pool, tokens => \@tokens);
    
    my $match_count = 0;
    for my $i (0..$#baseline) {
        $match_count++ if abs($logits_zero[$i] - $baseline[$i]) < 0.001;
    }
    my $match_pct = $match_count / scalar(@baseline) * 100;
    ok($match_pct > 99, "scale=0 produces near-baseline output ($match_pct% match)");
    diag("Baseline match: $match_pct%");
    
    $lora->scale(1);
    
    # Test different LoRA scales
    diag("\n=== Testing LoRA scale effects ===");
    
    $lora->scale(0.5);
    my @half_logits = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@half_logits > 0, "forward_with_pool with scale=0.5 succeeds");
    
    $lora->scale(2.0);
    my @double_logits = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@double_logits > 0, "forward_with_pool with scale=2.0 succeeds");
    
    my ($max_base, $max_half, $max_double) = (0, 0, 0);
    for my $i (0..$#baseline) {
        $max_base = abs($baseline[$i]) if abs($baseline[$i]) > $max_base;
        $max_half = abs($half_logits[$i]) if abs($half_logits[$i]) > $max_half;
        $max_double = abs($double_logits[$i]) if abs($double_logits[$i]) > $max_double;
    }
    diag(sprintf("Max logit - baseline: %.2f, scale=0.5: %.2f, scale=2.0: %.2f", 
                 $max_base, $max_half, $max_double));
    
    $lora->scale(1);
    diag("\nGGUF LoRA + memory pool integration complete!");
}

# Test SafeTensors LoRA with forward_with_pool
my $st_lora_file = "$Bin/data/test-lora.safetensors";

SKIP: {
    skip "SafeTensors test files not found", 8 unless -f $test_model && -f $st_lora_file;
    
    diag("\n=== Testing SafeTensors LoRA with memory pool ===");
    
    my $model = Lugh::Model->new(model => $test_model);
    my $inf = Lugh::Inference->new(model => $model);
    
    my $lora = Lugh::LoRA->new(model => $model, file => $st_lora_file);
    ok($lora, "SafeTensors LoRA loaded");
    is($lora->format, 'safetensors', "Format is safetensors");
    
    my $pool = $inf->create_memory_pool();
    my @tokens = (1, 2, 3);
    
    # Baseline
    my @baseline = $inf->forward_with_pool($pool, \@tokens);
    ok(@baseline > 0, "Baseline forward_with_pool succeeds");
    
    # With SafeTensors LoRA
    my @logits_lora = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@logits_lora > 0, "forward_with_pool with SafeTensors LoRA succeeds");
    is(scalar(@logits_lora), scalar(@baseline), "Output has correct length");
    
    # Scale=0 should match baseline
    $lora->scale(0);
    my @logits_zero = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    my @base2 = $inf->forward_with_pool($pool, \@tokens);
    
    my $match = 0;
    for my $i (0..$#base2) {
        $match++ if abs($logits_zero[$i] - $base2[$i]) < 0.001;
    }
    my $pct = $match / scalar(@base2) * 100;
    ok($pct > 99, "scale=0 matches baseline: $pct%");
    
    $lora->scale(1);
    my @final = $inf->forward_with_pool(pool => $pool, tokens => \@tokens, lora => $lora);
    ok(@final > 0, "scale=1 forward succeeds");
    
    diag("SafeTensors LoRA + memory pool integration complete!");
}

# Text output tests - verify LoRA actually changes predictions
SKIP: {
    skip "Test files not available for text tests", 6 
        unless -f $test_model && -f $lora_file && -f $st_lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    my $tok = Lugh::Tokenizer->new(model => $model);
    my $inf = Lugh::Inference->new(model => $model);
    my $gguf_lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    my $pool = $inf->create_memory_pool();
    
    diag("\n=== Text Output Tests for forward_with_pool ===");
    
    # Test with "The quick brown"
    my @prompt = $tok->encode("The quick brown");
    diag("Prompt: \"The quick brown\"");
    
    # Baseline prediction
    my @base_logits = $inf->forward_with_pool($pool, \@prompt);
    my @top_base = get_top_predictions(\@base_logits, $tok, 3);
    my $base_text = $top_base[0]{text};
    
    # LoRA prediction
    $gguf_lora->scale(1.0);
    my @lora_logits = $inf->forward_with_pool(pool => $pool, tokens => \@prompt, lora => $gguf_lora);
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
    my @zero_logits = $inf->forward_with_pool(pool => $pool, tokens => \@prompt, lora => $gguf_lora);
    my @top_zero = get_top_predictions(\@zero_logits, $tok, 1);
    is($top_zero[0]{text}, $base_text, 
       "scale=0 produces identical text: \"$top_zero[0]{text}\"");
    
    # Verify logits changed throughout vocab
    my $changed = 0;
    for my $i (0..$#base_logits) {
        $changed++ if abs($base_logits[$i] - $lora_logits[$i]) > 0.0001;
    }
    my $pct = 100 * $changed / scalar(@base_logits);
    ok($pct > 50, sprintf("LoRA modifies %.1f%% of all %d logits", $pct, scalar(@base_logits)));
    
    # Test second prompt
    my @prompt2 = $tok->encode("Hello world");
    my @base2 = $inf->forward_with_pool($pool, \@prompt2);
    $gguf_lora->scale(1.0);
    my @lora2 = $inf->forward_with_pool(pool => $pool, tokens => \@prompt2, lora => $gguf_lora);
    
    my @top_base2 = get_top_predictions(\@base2, $tok, 3);
    my @top_lora2 = get_top_predictions(\@lora2, $tok, 3);
    
    my $rank2_changed = 0;
    for my $i (0..2) {
        $rank2_changed++ if $top_base2[$i]{id} != $top_lora2[$i]{id};
    }
    diag("  \"Hello world\": rank changes = $rank2_changed");
    ok($rank2_changed > 0 || $top_base2[0]{text} ne $top_lora2[0]{text},
       "LoRA affects \"Hello world\" prediction");
    
    # Test with SafeTensors LoRA
    my $st_lora = Lugh::LoRA->new(model => $model, file => $st_lora_file);
    $st_lora->scale(1.0);
    my @st_logits = $inf->forward_with_pool(pool => $pool, tokens => \@prompt, lora => $st_lora);
    my @top_st = get_top_predictions(\@st_logits, $tok, 1);
    
    like($top_st[0]{text}, qr/.+/, "SafeTensors LoRA predicts: \"$top_st[0]{text}\"");
    
    diag("\n=== Pool text output tests complete ===\n");
}

done_testing();
