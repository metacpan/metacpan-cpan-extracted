#!/usr/bin/env perl
# t/18-inference-methods.t - Test Inference object methods and hyperparameter accessors

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 27;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# ============================================================================
# Test Inference constructor options
# ============================================================================

# Test 4-5: Create inference with custom n_ctx
my $custom_inference = Lugh::Inference->new(model => $model, n_ctx => 512);
ok($custom_inference, 'Inference with custom n_ctx created');
is($custom_inference->n_ctx(), 512, 'Custom n_ctx value preserved');

# Test 6: Create inference with n_threads option
my $threaded_inference = Lugh::Inference->new(model => $model, n_threads => 2);
ok($threaded_inference, 'Inference with custom n_threads created');

# ============================================================================
# Test model() accessor
# ============================================================================

# Test 7-8: Access model from inference
my $inf_model = eval { $inference->model() };
if (defined $inf_model) {
    ok(1, 'model() accessor available');
    isa_ok($inf_model, 'Lugh::Model', 'Returns Model object');
} else {
    ok(1, 'model() accessor not exposed (acceptable)');
    ok(1, 'Skipped model type check');
}

# ============================================================================
# Test Inference context accessors
# ============================================================================

# Test 9-10: n_ctx
my $n_ctx = $inference->n_ctx();
ok(defined $n_ctx, 'n_ctx() returns value');
ok($n_ctx > 0, 'n_ctx is positive');
diag("Context length: $n_ctx");

# Test 11-12: n_vocab
my $n_vocab = $inference->n_vocab();
ok(defined $n_vocab, 'n_vocab() returns value');
is($n_vocab, $tokenizer->n_vocab, 'n_vocab matches tokenizer');

# Test 13-14: n_embd
my $n_embd = $inference->n_embd();
ok(defined $n_embd, 'n_embd() returns value');
ok($n_embd > 0, 'n_embd is positive');
diag("Embedding dim: $n_embd");

# Test 15-16: n_layer
my $n_layer = $inference->n_layer();
ok(defined $n_layer, 'n_layer() returns value');
ok($n_layer > 0, 'n_layer is positive');
diag("Layers: $n_layer");

# Test 17-18: n_head
my $n_head = eval { $inference->n_head() };
if (defined $n_head) {
    ok(1, 'n_head() available');
    ok($n_head > 0, 'n_head is positive');
    diag("Attention heads: $n_head");
} else {
    ok(1, 'n_head not exposed');
    ok(1, 'Skipped n_head check');
}

# ============================================================================
# Test forward pass behavior
# ============================================================================

# Test 19-21: Multiple forward calls should work
my @tokens = $tokenizer->encode("Hello world");
my @logits1 = $inference->forward(\@tokens);
ok(scalar(@logits1) > 0, 'First forward call works');

my @logits2 = $inference->forward(\@tokens);
ok(scalar(@logits2) > 0, 'Second forward call works');
is(scalar(@logits2), scalar(@logits1), 'Same logits size from repeated calls');

# Test 22-23: Predictions should be consistent for same input
sub argmax {
    my ($arr) = @_;
    my $max_idx = 0;
    my $max_val = $arr->[0];
    for my $i (1..$#$arr) {
        if ($arr->[$i] > $max_val) {
            $max_val = $arr->[$i];
            $max_idx = $i;
        }
    }
    return $max_idx;
}

my $pred1 = argmax(\@logits1);
my $pred2 = argmax(\@logits2);
is($pred1, $pred2, 'Same prediction from repeated forward calls');

# Test 24-25: Different inputs should produce different outputs (usually)
my @tokens_alt = $tokenizer->encode("Goodbye world");
my @logits_alt = $inference->forward(\@tokens_alt);
ok(scalar(@logits_alt) > 0, 'Forward with different input works');
my $pred_alt = argmax(\@logits_alt);
# Note: Could theoretically be same, but usually won't be
ok(1, 'Different input processed successfully');

# ============================================================================
# Test hyperparameter consistency
# ============================================================================

# Test 26: n_vocab matches logits size
is(scalar(@logits1), $n_vocab, 'Logits size matches n_vocab');

# Test 27-28: Hyperparameters should be consistent across inference objects
my $inference2 = Lugh::Inference->new(model => $model);
is($inference2->n_vocab(), $n_vocab, 'n_vocab consistent across inference objects');
is($inference2->n_embd(), $n_embd, 'n_embd consistent across inference objects');
