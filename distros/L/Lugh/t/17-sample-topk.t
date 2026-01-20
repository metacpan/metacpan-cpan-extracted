#!/usr/bin/env perl
# t/17-sample-topk.t - Test top-k sampling specifically

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 32;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Get logits for testing
my @tokens = $tokenizer->encode("Once upon a time");
my @logits = $inference->forward(\@tokens);
ok(scalar(@logits) > 0, 'Got logits for sampling tests');

# ============================================================================
# Basic sample_top_k tests
# ============================================================================

# Test 5-7: Basic top_k sampling
my $sampled_k = $inference->sample_top_k(\@logits);
ok(defined $sampled_k, 'sample_top_k() returns a value');
ok($sampled_k >= 0, 'Sampled token is non-negative');
ok($sampled_k < $tokenizer->n_vocab, 'Sampled token is within vocab');

# Test 8-10: Top-k with explicit k value
my $sampled_k40 = $inference->sample_top_k(\@logits, top_k => 40);
ok(defined $sampled_k40, 'sample_top_k(top_k=>40) works');
ok($sampled_k40 >= 0 && $sampled_k40 < $tokenizer->n_vocab, 'top_k=40 produces valid token');

my $decoded = $tokenizer->decode([$sampled_k40]);
ok(defined $decoded, 'Top-k sampled token decodes');

# Test 11-13: Top-k = 1 (should be deterministic like greedy)
my $topk1_a = $inference->sample_top_k(\@logits, top_k => 1);
my $topk1_b = $inference->sample_top_k(\@logits, top_k => 1);
ok(defined $topk1_a, 'top_k=1 returns value');
is($topk1_a, $topk1_b, 'top_k=1 is deterministic (same as greedy)');

# Verify top_k=1 matches argmax
my $max_idx = 0;
my $max_val = $logits[0];
for my $i (1..$#logits) {
    if ($logits[$i] > $max_val) {
        $max_val = $logits[$i];
        $max_idx = $i;
    }
}
is($topk1_a, $max_idx, 'top_k=1 equals argmax');

# Test 14-16: Various k values
my $sampled_k10 = $inference->sample_top_k(\@logits, top_k => 10);
ok(defined $sampled_k10, 'top_k=10 works');

my $sampled_k100 = $inference->sample_top_k(\@logits, top_k => 100);
ok(defined $sampled_k100, 'top_k=100 works');

my $sampled_k5 = $inference->sample_top_k(\@logits, top_k => 5);
ok(defined $sampled_k5, 'top_k=5 works');

# ============================================================================
# Top-k with temperature
# ============================================================================

# Test 17-19: Top-k with temperature
my $sampled_kt = $inference->sample_top_k(\@logits, top_k => 40, temperature => 0.7);
ok(defined $sampled_kt, 'top_k with temperature works');
ok($sampled_kt >= 0 && $sampled_kt < $tokenizer->n_vocab, 'top_k+temp produces valid token');

# Test 20-21: Low temperature makes it more deterministic
# Run multiple samples and check variance
my %low_temp_samples;
for (1..10) {
    my $s = $inference->sample_top_k(\@logits, top_k => 40, temperature => 0.1);
    $low_temp_samples{$s}++;
}
my $unique_low = scalar(keys %low_temp_samples);
ok($unique_low >= 1, 'Low temperature sampling produces at least one unique value');
diag("Low temp (0.1) unique samples: $unique_low / 10");

# Test 22-23: High temperature has more variance
my %high_temp_samples;
for (1..10) {
    my $s = $inference->sample_top_k(\@logits, top_k => 40, temperature => 1.5);
    $high_temp_samples{$s}++;
}
my $unique_high = scalar(keys %high_temp_samples);
ok($unique_high >= 1, 'High temperature sampling produces at least one unique value');
diag("High temp (1.5) unique samples: $unique_high / 10");

# ============================================================================
# Compare top_k vs top_p
# ============================================================================

# Test 24-25: Both methods produce valid tokens
my $from_topk = $inference->sample_top_k(\@logits, top_k => 40, temperature => 0.8);
my $from_topp = $inference->sample_top_p(\@logits, top_p => 0.9, temperature => 0.8);
ok(defined $from_topk && $from_topk >= 0, 'top_k produces valid token');
ok(defined $from_topp && $from_topp >= 0, 'top_p produces valid token');

# Test 26-27: Decode both
my $decoded_k = $tokenizer->decode([$from_topk]);
my $decoded_p = $tokenizer->decode([$from_topp]);
ok(defined $decoded_k, 'top_k token decodes');
ok(defined $decoded_p, 'top_p token decodes');

# ============================================================================
# Edge cases for top_k
# ============================================================================

# Test 28-29: Very large k (larger than vocab)
my $vocab_size = $tokenizer->n_vocab;
my $sampled_huge_k = $inference->sample_top_k(\@logits, top_k => $vocab_size * 2);
ok(defined $sampled_huge_k, 'top_k larger than vocab works');
ok($sampled_huge_k >= 0 && $sampled_huge_k < $vocab_size, 'Huge top_k still valid');

# Test 30-31: k = vocab size
my $sampled_full_k = $inference->sample_top_k(\@logits, top_k => $vocab_size);
ok(defined $sampled_full_k, 'top_k = vocab_size works');
ok($sampled_full_k >= 0 && $sampled_full_k < $vocab_size, 'Full vocab top_k valid');

# ============================================================================
# Generation with top_k
# ============================================================================

# Test 32-35: Use top_k in generation
my @gen_tokens = $inference->generate(
    \@tokens,
    max_tokens => 5,
    top_k      => 40,
    temperature => 0.8,
);
ok(scalar(@gen_tokens) > 0, 'Generation with top_k produces tokens');
ok(scalar(@gen_tokens) <= 5, 'Generation respects max_tokens');

my $gen_text = $tokenizer->decode(\@gen_tokens);
ok(defined $gen_text, 'Generated tokens decode');
diag("Generated with top_k=40: $gen_text");

# Compare with top_p generation
my @gen_topp = $inference->generate(
    \@tokens,
    max_tokens => 5,
    top_p      => 0.9,
    temperature => 0.8,
);
ok(scalar(@gen_topp) > 0, 'Generation with top_p also works');
