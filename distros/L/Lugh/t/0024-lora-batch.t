#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);

# Test LoRA integration with forward_batch

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
    skip "Test model not found", 16 unless -f $test_model && -f $lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    ok($model, "Test model loaded");
    diag("Model: " . $model->architecture);
    
    my $inf = Lugh::Inference->new(model => $model);
    ok($inf, "Inference context created");
    
    my $lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    ok($lora, "LoRA adapter loaded");
    diag("LoRA weights: " . $lora->n_weights . ", alpha: " . $lora->alpha);
    
    my @sequences = ([1, 2, 3], [4, 5], [6, 7, 8, 9]);
    diag("\n=== Testing forward_batch ===");
    diag("Sequences: " . scalar(@sequences));
    
    # Test positional args (no LoRA) - returns arrayref of arrayrefs
    my ($results1) = $inf->forward_batch(\@sequences);
    ok(ref($results1) eq 'ARRAY' && @$results1 == 3, "forward_batch (positional) returns 3 results");
    diag("Positional call returned " . scalar(@$results1) . " result arrays");
    for my $i (0..$#$results1) {
        my $len = ref($results1->[$i]) eq 'ARRAY' ? scalar(@{$results1->[$i]}) : 0;
        diag("  Sequence $i: $len logits");
    }
    
    # Test named args (no LoRA)
    my ($results2) = $inf->forward_batch(sequences => \@sequences);
    ok(ref($results2) eq 'ARRAY' && @$results2 == 3, "forward_batch (named) returns 3 results");
    diag("Named call returned " . scalar(@$results2) . " result arrays");
    
    # Test with LoRA
    diag("\n=== Testing with LoRA ===");
    my ($results_lora) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($results_lora) eq 'ARRAY' && @$results_lora == 3, "forward_batch with LoRA returns 3 results");
    diag("LoRA call returned " . scalar(@$results_lora) . " result arrays");
    for my $i (0..$#$results_lora) {
        my $len = ref($results_lora->[$i]) eq 'ARRAY' ? scalar(@{$results_lora->[$i]}) : 0;
        diag("  Sequence $i: $len logits");
    }
    
    # Test with scale=0 (should match baseline)
    diag("\n=== Testing scale=0 (should match baseline) ===");
    $lora->scale(0);
    my ($results_zero) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($results_zero) eq 'ARRAY' && @$results_zero == 3, "forward_batch with scale=0 succeeds");
    
    my ($baseline) = $inf->forward_batch(sequences => \@sequences);
    
    my $total_match = 0;
    my $total_count = 0;
    for my $i (0..$#$baseline) {
        my $base = $baseline->[$i];
        my $zero = $results_zero->[$i];
        next unless ref($base) eq 'ARRAY' && ref($zero) eq 'ARRAY';
        for my $j (0..$#$base) {
            $total_count++;
            $total_match++ if abs($base->[$j] - $zero->[$j]) < 0.001;
        }
    }
    my $match_pct = $total_count > 0 ? ($total_match / $total_count * 100) : 0;
    ok($match_pct > 99, "scale=0 produces near-baseline output ($match_pct% match)");
    diag("Baseline match: $match_pct%");
    
    $lora->scale(1);
    
    # Test different LoRA scales
    diag("\n=== Testing LoRA scale effects ===");
    
    $lora->scale(0.5);
    my ($half_results) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($half_results) eq 'ARRAY' && @$half_results == 3, "forward_batch with scale=0.5 succeeds");
    
    $lora->scale(2.0);
    my ($double_results) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($double_results) eq 'ARRAY' && @$double_results == 3, "forward_batch with scale=2.0 succeeds");
    
    $lora->scale(1);
    diag("\nGGUF LoRA + batch processing integration complete!");
}

# Test SafeTensors LoRA with forward_batch
my $st_lora_file = "$Bin/data/test-lora.safetensors";

SKIP: {
    skip "SafeTensors test files not found", 8 unless -f $test_model && -f $st_lora_file;
    
    diag("\n=== Testing SafeTensors LoRA with batch processing ===");
    
    my $model = Lugh::Model->new(model => $test_model);
    my $inf = Lugh::Inference->new(model => $model);
    
    my $lora = Lugh::LoRA->new(model => $model, file => $st_lora_file);
    ok($lora, "SafeTensors LoRA loaded");
    is($lora->format, 'safetensors', "Format is safetensors");
    
    my @sequences = ([1, 2, 3], [4, 5], [6, 7, 8, 9]);
    
    # Baseline
    my ($baseline) = $inf->forward_batch(\@sequences);
    ok(ref($baseline) eq 'ARRAY' && @$baseline == 3, "Baseline forward_batch succeeds");
    
    # With SafeTensors LoRA
    my ($results_lora) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($results_lora) eq 'ARRAY' && @$results_lora == 3, "forward_batch with SafeTensors LoRA succeeds");
    
    # Scale=0 should match baseline
    $lora->scale(0);
    my ($results_zero) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    my ($base2) = $inf->forward_batch(\@sequences);
    
    my $total_match = 0;
    my $total_count = 0;
    for my $i (0..$#$base2) {
        next unless ref($base2->[$i]) eq 'ARRAY' && ref($results_zero->[$i]) eq 'ARRAY';
        for my $j (0..$#{$base2->[$i]}) {
            $total_count++;
            $total_match++ if abs($base2->[$i][$j] - $results_zero->[$i][$j]) < 0.001;
        }
    }
    my $pct = $total_count > 0 ? ($total_match / $total_count * 100) : 0;
    ok($pct > 99, "scale=0 matches baseline: $pct%");
    
    $lora->scale(1);
    my ($final) = $inf->forward_batch(sequences => \@sequences, lora => $lora);
    ok(ref($final) eq 'ARRAY' && @$final == 3, "scale=1 forward_batch succeeds");
    
    diag("SafeTensors LoRA + batch processing integration complete!");
}

# Text output tests - verify LoRA actually changes predictions in batch
SKIP: {
    skip "Test files not available for text tests", 6 
        unless -f $test_model && -f $lora_file && -f $st_lora_file;
    
    my $model = Lugh::Model->new(model => $test_model);
    my $tok = Lugh::Tokenizer->new(model => $model);
    my $inf = Lugh::Inference->new(model => $model);
    my $gguf_lora = Lugh::LoRA->new(model => $model, file => $lora_file);
    
    diag("\n=== Text Output Tests for forward_batch ===");
    
    # Create batch of prompts
    my @prompt1 = $tok->encode("The quick brown");
    my @prompt2 = $tok->encode("Once upon a time");
    my @prompt3 = $tok->encode("Hello world");
    
    my @sequences = (\@prompt1, \@prompt2, \@prompt3);
    diag("Batch of 3 prompts");
    
    # Baseline predictions
    my ($base_results) = $inf->forward_batch(\@sequences);
    
    # LoRA predictions
    $gguf_lora->scale(1.0);
    my ($lora_results) = $inf->forward_batch(sequences => \@sequences, lora => $gguf_lora);
    
    # Check each sequence
    my @prompts = ("The quick brown", "Once upon a time", "Hello world");
    my $total_rank_changes = 0;
    my $text_changed_count = 0;
    
    for my $i (0..2) {
        my @top_base = get_top_predictions($base_results->[$i], $tok, 3);
        my @top_lora = get_top_predictions($lora_results->[$i], $tok, 3);
        
        my $base_text = $top_base[0]{text};
        my $lora_text = $top_lora[0]{text};
        
        diag("  \"$prompts[$i]\": \"$base_text\" -> \"$lora_text\"");
        
        $text_changed_count++ if $base_text ne $lora_text;
        
        for my $j (0..2) {
            $total_rank_changes++ if $top_base[$j]{id} != $top_lora[$j]{id};
        }
    }
    
    # At least one sequence should have different text
    ok($text_changed_count > 0, 
       "LoRA changes text in $text_changed_count of 3 sequences");
    
    # Rankings should change across batch
    ok($total_rank_changes > 0, 
       "LoRA changes $total_rank_changes total ranking positions across batch");
    
    # scale=0 must match baseline for all sequences
    $gguf_lora->scale(0);
    my ($zero_results) = $inf->forward_batch(sequences => \@sequences, lora => $gguf_lora);
    my ($base2) = $inf->forward_batch(\@sequences);
    
    my $all_match = 1;
    for my $i (0..2) {
        my @top_zero = get_top_predictions($zero_results->[$i], $tok, 1);
        my @top_base = get_top_predictions($base2->[$i], $tok, 1);
        if ($top_zero[0]{text} ne $top_base[0]{text}) {
            $all_match = 0;
            last;
        }
    }
    ok($all_match, "scale=0 produces identical text for all sequences");
    
    # Verify logits changed throughout vocab for first sequence
    my $changed = 0;
    for my $j (0..$#{$base_results->[0]}) {
        $changed++ if abs($base_results->[0][$j] - $lora_results->[0][$j]) > 0.0001;
    }
    my $pct = 100 * $changed / scalar(@{$base_results->[0]});
    ok($pct > 50, sprintf("LoRA modifies %.1f%% of logits in sequence 1", $pct));
    
    # Test SafeTensors LoRA with batch
    my $st_lora = Lugh::LoRA->new(model => $model, file => $st_lora_file);
    $st_lora->scale(1.0);
    my ($st_results) = $inf->forward_batch(sequences => \@sequences, lora => $st_lora);
    
    ok(ref($st_results) eq 'ARRAY' && @$st_results == 3, 
       "SafeTensors LoRA batch returns 3 results");
    
    my @top_st = get_top_predictions($st_results->[0], $tok, 1);
    like($top_st[0]{text}, qr/.+/, 
       "SafeTensors LoRA predicts: \"$top_st[0]{text}\"");
    
    diag("\n=== Batch text output tests complete ===\n");
}

done_testing();
