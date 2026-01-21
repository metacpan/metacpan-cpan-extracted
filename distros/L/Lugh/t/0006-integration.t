#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Lugh;

# Use bundled test model
my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 31;

# === Integration Test: Full Pipeline ===

# Load all components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Test 1: Single-step generation
my $prompt1 = "The capital of France is";
my @tokens1 = $tokenizer->encode($prompt1);
ok(scalar(@tokens1) > 0, 'Prompt encoded');

my @logits1 = $inference->forward_simple(\@tokens1);
ok(scalar(@logits1) > 0, 'Forward pass produced logits');

my $next_token1 = $inference->sample_top_p(\@logits1, temperature => 0.1);
ok(defined $next_token1, 'Sampled next token');

my $next_word1 = $tokenizer->decode([$next_token1]);
ok(defined $next_word1, 'Decoded next token');

# Test 2: Multi-step generation (5 tokens)
my $prompt2 = "Once upon a time";
my @tokens2 = $tokenizer->encode($prompt2);
my $generated_text = "";

for my $step (1..5) {
    my @logits = $inference->forward_simple(\@tokens2);
    my $next = $inference->sample_top_p(\@logits, temperature => 0.8, top_p => 0.9);

    ok($next >= 0 && $next < $tokenizer->n_vocab, "Step $step: valid token");

    last if $next == $tokenizer->eos_id;

    push @tokens2, $next;
    my $word = $tokenizer->decode([$next]);
    $generated_text .= $word;
}

ok(length($generated_text) > 0, 'Generated text is not empty');

# Test 3: Consistent predictions (greedy decoding should be deterministic)
# Test with story-appropriate prompts for the tiny stories model
my @story1_tokens = $tokenizer->encode("Once upon a time there was");
my @story1_logits = $inference->forward_simple(\@story1_tokens);
my $story1_pred = greedy_sample(\@story1_logits);
my $story1_word = $tokenizer->decode([$story1_pred]);
ok(defined $story1_word, 'Story prompt 1 prediction exists');

# Verify same input produces same output (determinism)
my @story1_logits_again = $inference->forward_simple(\@story1_tokens);
my $story1_pred_again = greedy_sample(\@story1_logits_again);
is($story1_pred, $story1_pred_again, 'Greedy decoding is deterministic');

# Another prompt
my @story2_tokens = $tokenizer->encode("The little girl");
my @story2_logits = $inference->forward_simple(\@story2_tokens);
my $story2_pred = greedy_sample(\@story2_logits);
my $story2_word = $tokenizer->decode([$story2_pred]);
ok(defined $story2_word, 'Story prompt 2 prediction exists');

# Test 4: Round-trip with generation
my $original_prompt = "Once upon a time";
my @orig_tokens = $tokenizer->encode($original_prompt);
my @gen_logits = $inference->forward_simple(\@orig_tokens);
my $gen_token = greedy_sample(\@gen_logits);
push @orig_tokens, $gen_token;

my $full_text = $tokenizer->decode(\@orig_tokens);
ok(length($full_text) > length($original_prompt), 'Generated text is longer than original');

# Test 5: Different sampling strategies
my $test_prompt = "The little dog";
my @test_tokens = $tokenizer->encode($test_prompt);
my @test_logits = $inference->forward_simple(\@test_tokens);

# Greedy (temperature → 0)
my $greedy1 = greedy_sample(\@test_logits);
my $greedy2 = greedy_sample(\@test_logits);
is($greedy1, $greedy2, 'Greedy sampling is deterministic');

# Low temperature (focused)
my $focused = $inference->sample_top_p(\@test_logits, temperature => 0.1, top_p => 0.5);
ok(defined $focused, 'Low temperature sampling works');

# High temperature (creative)
my $creative = $inference->sample_top_p(\@test_logits, temperature => 1.5, top_p => 0.95);
ok(defined $creative, 'High temperature sampling works');

# Test 6: Generation until EOS (limited steps)
my $eos_prompt = "The end.";
my @eos_tokens = $tokenizer->encode($eos_prompt);
my $max_steps = 20;
my $hit_eos = 0;

for my $step (1..$max_steps) {
    my @logits = $inference->forward_simple(\@eos_tokens);
    my $next = $inference->sample_top_p(\@logits, temperature => 0.8);

    if ($next == $tokenizer->eos_id) {
        $hit_eos = 1;
        last;
    }

    push @eos_tokens, $next;
}

# It's OK if we don't hit EOS in 20 steps
ok(scalar(@eos_tokens) <= $max_steps + scalar($tokenizer->encode($eos_prompt)),
   'Generation respects max steps');

# Test 7: Consistency across multiple runs
my $consistency_prompt = "2 + 2 equals";
my @cons_tokens = $tokenizer->encode($consistency_prompt);

my @run1_logits = $inference->forward_simple(\@cons_tokens);
my @run2_logits = $inference->forward_simple(\@cons_tokens);

# Compare first and last logits
is($run1_logits[0], $run2_logits[0], 'First logit consistent');
is($run1_logits[-1], $run2_logits[-1], 'Last logit consistent');

# Compare predictions
my $pred1 = greedy_sample(\@run1_logits);
my $pred2 = greedy_sample(\@run2_logits);
is($pred1, $pred2, 'Predictions are consistent');

# Test 8: Different prompt lengths
my @short = $tokenizer->encode("Hi");
my @medium = $tokenizer->encode("Hello, how are you today?");
my @long = $tokenizer->encode("Once upon a time in a land far far away, there lived a wise old wizard.");

my @short_logits = $inference->forward_simple(\@short);
my @medium_logits = $inference->forward_simple(\@medium);
my @long_logits = $inference->forward_simple(\@long);

is(scalar(@short_logits), $tokenizer->n_vocab, 'Short prompt: correct logits size');
is(scalar(@medium_logits), $tokenizer->n_vocab, 'Medium prompt: correct logits size');
is(scalar(@long_logits), $tokenizer->n_vocab, 'Long prompt: correct logits size');

# All should produce different predictions
my $short_pred = greedy_sample(\@short_logits);
my $medium_pred = greedy_sample(\@medium_logits);
my $long_pred = greedy_sample(\@long_logits);

ok($short_pred != $medium_pred || $medium_pred != $long_pred,
   'Different prompts produce different predictions');

# Test 9: Streaming generation simulation
my $stream_prompt = "The sky is";
my @stream_tokens = $tokenizer->encode($stream_prompt);
my $streamed = "";

for (1..3) {
    my @logits = $inference->forward_simple(\@stream_tokens);
    my $next = greedy_sample(\@logits);
    last if $next == $tokenizer->eos_id;

    my $token_text = $tokenizer->decode([$next]);
    $streamed .= $token_text;
    push @stream_tokens, $next;
}

ok(length($streamed) > 0, 'Streaming generation produces text');

# Test 10: Full generation helper function
sub generate_tokens {
    my ($inference, $tokenizer, $tokens_ref, $max_new, $temp, $topp) = @_;
    my @generated;

    for (1..$max_new) {
        my @logits = $inference->forward_simple($tokens_ref);
        my $next = $inference->sample_top_p(\@logits,
            temperature => $temp,
            top_p => $topp
        );

        last if $next == $tokenizer->eos_id;

        push @$tokens_ref, $next;
        push @generated, $next;
    }

    return @generated;
}

my $gen_prompt = "In the beginning";
my @gen_tokens = $tokenizer->encode($gen_prompt);
my @new_tokens = generate_tokens($inference, $tokenizer, \@gen_tokens, 8, 0.8, 0.9);

ok(scalar(@new_tokens) <= 8, 'Helper generates limited tokens');
my $final_text = $tokenizer->decode(\@gen_tokens);
like($final_text, qr/beginning/, 'Final text contains original prompt');

# Helper function for greedy sampling
sub greedy_sample {
    my ($logits_ref) = @_;
    my $max_idx = 0;
    my $max_val = $logits_ref->[0];

    for my $i (1..$#{$logits_ref}) {
        if ($logits_ref->[$i] > $max_val) {
            $max_val = $logits_ref->[$i];
            $max_idx = $i;
        }
    }

    return $max_idx;
}

done_testing();
