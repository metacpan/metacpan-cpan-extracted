#!/usr/bin/env perl
# t/15-batch.t - Test batch processing of multiple sequences

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 31;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Test 4-6: Encode multiple prompts
my @prompts = (
    "Once upon a time",
    "The quick brown fox",
    "Hello world",
);

my @sequences;
for my $prompt (@prompts) {
    push @sequences, [$tokenizer->encode($prompt)];
}
is(scalar(@sequences), 3, 'Encoded 3 sequences');
ok(scalar(@{$sequences[0]}) > 0, 'First sequence has tokens');
ok(scalar(@{$sequences[1]}) > 0, 'Second sequence has tokens');

# Test 7-10: Batch forward pass
my $batch_result = $inference->forward_batch(\@sequences);
ok($batch_result, 'forward_batch returns result');
isa_ok($batch_result, 'ARRAY', 'Batch result is array');
is(scalar(@$batch_result), 3, 'Got results for all 3 sequences');

# Test 11-14: Each result has correct logits
for my $i (0..2) {
    my $logits = $batch_result->[$i];
    ok(ref($logits) eq 'ARRAY', "Result $i is array");
    is(scalar(@$logits), $tokenizer->n_vocab, "Result $i has correct vocab size")
        if ref($logits) eq 'ARRAY';
}

# Test 15-17: Batch results match individual forward passes
my @individual_results;
for my $seq (@sequences) {
    my @logits = $inference->forward_simple($seq);
    push @individual_results, \@logits;
}

# Helper to get argmax
sub argmax {
    my ($arr) = @_;
    return 0 unless ref($arr) eq 'ARRAY' && @$arr;
    my $max_idx = 0;
    my $max_val = $arr->[0] // -1e10;
    for my $i (1..$#$arr) {
        if (($arr->[$i] // -1e10) > $max_val) {
            $max_val = $arr->[$i];
            $max_idx = $i;
        }
    }
    return $max_idx;
}

for my $i (0..2) {
    my $batch_pred = argmax($batch_result->[$i]);
    my $indiv_pred = argmax($individual_results[$i]);
    is($batch_pred, $indiv_pred, "Sequence $i: batch prediction matches individual");
}

# Test 18-20: Different length sequences in batch
my @varied_sequences = (
    [$tokenizer->encode("Hi")],                              # Very short
    [$tokenizer->encode("Once upon a time there was")],      # Medium
    [$tokenizer->encode("The")],                             # Single word
);

my $varied_result = $inference->forward_batch(\@varied_sequences);
ok($varied_result, 'Batch with varied lengths returns result');
is(scalar(@$varied_result), 3, 'Got results for varied length sequences');
ok(ref($varied_result->[0]) eq 'ARRAY', 'Varied batch result is array of arrays');

# Test 21-23: Single sequence batch
my @single_sequence = ([$tokenizer->encode("Test")]);
my $single_result = $inference->forward_batch(\@single_sequence);
ok($single_result, 'Single sequence batch works');
is(scalar(@$single_result), 1, 'Single sequence returns one result');

my @direct_logits = $inference->forward_simple($single_sequence[0]);
my $single_pred = argmax($single_result->[0]);
my $direct_pred = argmax(\@direct_logits);
is($single_pred, $direct_pred, 'Single batch matches direct forward');

# Test 24-26: Larger batch
my @large_batch;
for my $i (1..5) {
    push @large_batch, [$tokenizer->encode("Prompt number $i")];
}
my $large_result = $inference->forward_batch(\@large_batch);
ok($large_result, 'Larger batch (5 sequences) works');
is(scalar(@$large_result), 5, 'Got all 5 results');

my $all_valid = 1;
for my $r (@$large_result) {
    unless (ref($r) eq 'ARRAY' && scalar(@$r) == $tokenizer->n_vocab) {
        $all_valid = 0;
        last;
    }
}
ok($all_valid, 'All large batch results have correct size');

# Test 27-28: Sample from batch results
my $sample_0 = $inference->sample_top_p($batch_result->[0], temperature => 0.8);
my $sample_1 = $inference->sample_top_p($batch_result->[1], temperature => 0.8);
ok(defined $sample_0 && $sample_0 >= 0, 'Can sample from batch result 0');
ok(defined $sample_1 && $sample_1 >= 0, 'Can sample from batch result 1');

# Test 29-30: Decode sampled tokens
my $decoded_0 = $tokenizer->decode([$sample_0]);
my $decoded_1 = $tokenizer->decode([$sample_1]);
ok(defined $decoded_0, 'Batch sample 0 decodes');
ok(defined $decoded_1, 'Batch sample 1 decodes');

diag("Batch predictions: " . join(", ", map { $tokenizer->decode([argmax($_)]) } @$batch_result));
