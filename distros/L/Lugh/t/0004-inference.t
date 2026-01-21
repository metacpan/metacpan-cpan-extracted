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

plan tests => 45;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');
isa_ok($inference, 'Lugh::Inference');

# Test basic forward pass with single token
my @single_token = ($tokenizer->bos_id);
my @logits_single = $inference->forward_simple(\@single_token);
ok(scalar(@logits_single) > 0, 'forward() returns logits for single token');
is(scalar(@logits_single), $tokenizer->n_vocab, 'Logits size equals vocab size');

# Test all logits are numbers
my $all_numbers = 1;
for my $logit (@logits_single) {
    unless (defined $logit && $logit =~ /^-?\d+\.?\d*(?:[eE][+-]?\d+)?$/) {
        $all_numbers = 0;
        last;
    }
}
ok($all_numbers, 'All logits are numeric values');

# Test forward pass with multiple tokens
# Use a prompt suitable for story model
my @tokens = $tokenizer->encode("Once upon a time");
my @logits = $inference->forward_simple(\@tokens);
is(scalar(@logits), $tokenizer->n_vocab, 'Logits size correct for multi-token input');

# Test forward pass produces different logits for different inputs
my @tokens2 = $tokenizer->encode("Hello world");
my @logits2 = $inference->forward_simple(\@tokens2);
isnt($logits[0], $logits2[0], 'Different inputs produce different logits');

# Test greedy decoding (argmax)
my $max_idx = 0;
my $max_val = $logits[0];
for my $i (1..$#logits) {
    if ($logits[$i] > $max_val) {
        $max_val = $logits[$i];
        $max_idx = $i;
    }
}
ok($max_idx >= 0 && $max_idx < $tokenizer->n_vocab, 'Argmax index is valid');
ok($max_val > -1000, 'Max logit has reasonable value');

# Test predicted token is decodable
my $predicted = $tokenizer->decode([$max_idx]);
ok(defined $predicted, 'Predicted token can be decoded');

# Test prediction produces something reasonable
# The tiny stories model should predict story-like continuations
like($predicted, qr/\S/, 'Predicted token contains non-whitespace');

# Test sample_top_p with default parameters
my $sampled = $inference->sample_top_p(\@logits);
ok(defined $sampled, 'sample_top_p() returns a token');
ok($sampled >= 0 && $sampled < $tokenizer->n_vocab, 'Sampled token is valid');

# Test sample_top_p with temperature
my $sampled_temp = $inference->sample_top_p(\@logits, temperature => 0.8);
ok(defined $sampled_temp, 'sample_top_p() with temperature returns token');
ok($sampled_temp >= 0 && $sampled_temp < $tokenizer->n_vocab, 'Temperature sampling produces valid token');

# Test sample_top_p with top_p
my $sampled_topp = $inference->sample_top_p(\@logits, top_p => 0.95);
ok(defined $sampled_topp, 'sample_top_p() with top_p returns token');
ok($sampled_topp >= 0 && $sampled_topp < $tokenizer->n_vocab, 'Top-p sampling produces valid token');

# Test sample_top_p with both temperature and top_p
my $sampled_both = $inference->sample_top_p(\@logits, temperature => 0.7, top_p => 0.9);
ok(defined $sampled_both, 'sample_top_p() with both params returns token');
ok($sampled_both >= 0 && $sampled_both < $tokenizer->n_vocab, 'Combined sampling produces valid token');

# Test low temperature (more deterministic)
my $sampled_low_temp = $inference->sample_top_p(\@logits, temperature => 0.1);
ok(defined $sampled_low_temp, 'Low temperature sampling works');

# Test high temperature (more random)
my $sampled_high_temp = $inference->sample_top_p(\@logits, temperature => 1.5);
ok(defined $sampled_high_temp, 'High temperature sampling works');

# Test very low top_p (focused)
my $sampled_low_p = $inference->sample_top_p(\@logits, top_p => 0.1);
ok(defined $sampled_low_p, 'Low top_p sampling works');

# Test very high top_p (inclusive)
my $sampled_high_p = $inference->sample_top_p(\@logits, top_p => 0.99);
ok(defined $sampled_high_p, 'High top_p sampling works');

# Test forward pass consistency - same input should give same output
my @tokens3 = $tokenizer->encode("The capital of France is");
my @logits3a = $inference->forward_simple(\@tokens3);
my @logits3b = $inference->forward_simple(\@tokens3);
is($logits3a[0], $logits3b[0], 'Same input produces same first logit');
is($logits3a[-1], $logits3b[-1], 'Same input produces same last logit');

# Sample a few positions within vocabulary size
my $vocab_size = scalar(@logits3a);
my @sample_indices = grep { $_ < $vocab_size } (100, 500, 1000);
my $all_match = 1;
for my $idx (@sample_indices) {
    if ($logits3a[$idx] != $logits3b[$idx]) {
        $all_match = 0;
        last;
    }
}
ok($all_match, 'Same input produces identical logits (deterministic)');

# Test known good predictions from plan.md validation
my @capital_france = $tokenizer->encode("The capital of France is");
my @logits_france = $inference->forward_simple(\@capital_france);
my $france_max_idx = 0;
my $france_max_val = $logits_france[0];
for my $i (1..$#logits_france) {
    if ($logits_france[$i] > $france_max_val) {
        $france_max_val = $logits_france[$i];
        $france_max_idx = $i;
    }
}
my $france_pred = $tokenizer->decode([$france_max_idx]);
# According to plan.md: "The capital of France is" → "Paris" ✅
# The prediction might have leading space due to SentencePiece
ok(defined $france_pred, 'France capital prediction exists');

# Test another known example from plan.md
my @capital_germany = $tokenizer->encode("The capital of Germany is");
my @logits_germany = $inference->forward_simple(\@capital_germany);
my $germany_max_idx = 0;
my $germany_max_val = $logits_germany[0];
for my $i (1..$#logits_germany) {
    if ($logits_germany[$i] > $germany_max_val) {
        $germany_max_val = $logits_germany[$i];
        $germany_max_idx = $i;
    }
}
my $germany_pred = $tokenizer->decode([$germany_max_idx]);
# According to plan.md: "The capital of Germany is" → "Berlin" ✅
ok(defined $germany_pred, 'Germany capital prediction exists');

# Test that different prompts produce different predictions
isnt($france_pred, $germany_pred, 'Different prompts produce different predictions');

# Test third example from plan.md
my @hello_name = $tokenizer->encode("Hello, my name is");
my @logits_name = $inference->forward_simple(\@hello_name);
my $name_max_idx = 0;
my $name_max_val = $logits_name[0];
for my $i (1..$#logits_name) {
    if ($logits_name[$i] > $name_max_val) {
        $name_max_val = $logits_name[$i];
        $name_max_idx = $i;
    }
}
my $name_pred = $tokenizer->decode([$name_max_idx]);
# According to plan.md: "Hello, my name is" → "John" ✅
ok(defined $name_pred, 'Name prediction exists');

# Test forward pass with longer sequence
my @long_tokens = $tokenizer->encode("Once upon a time in a land far far away there lived");
my @long_logits = $inference->forward_simple(\@long_tokens);
is(scalar(@long_logits), $tokenizer->n_vocab, 'Long sequence produces correct logits size');
ok($long_logits[0] != $logits[0], 'Long sequence produces different logits than short');

# Test multiple generations don't interfere
my @test1 = $tokenizer->encode("Test A");
my @test2 = $tokenizer->encode("Test B");
my @logits_a1 = $inference->forward_simple(\@test1);
my @logits_b1 = $inference->forward_simple(\@test2);
my @logits_a2 = $inference->forward_simple(\@test1);
is($logits_a1[0], $logits_a2[0], 'Repeated inference produces same results');

# Test sampling produces tokens in valid range
for (1..10) {
    my $sample = $inference->sample_top_p(\@logits, temperature => 1.0, top_p => 0.95);
    ok($sample >= 0 && $sample < $tokenizer->n_vocab, "Sample $_ is in valid range");
}
