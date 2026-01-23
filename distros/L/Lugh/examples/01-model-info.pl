#!/usr/bin/env perl
#
# Lugh - Pure C LLM Inference Engine for Perl
# 
# This example demonstrates loading a GGUF model and tokenizing text.
# Full inference requires implementing the transformer forward pass.
#

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Lugh;

# Load a GGUF model
print "Loading TinyLlama model...\n";
my $model = Lugh::Model->new(
    model => 'models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf'
);

print "\n=== Model Information ===\n";
print "File: ", $model->filename, "\n";
print "Architecture: ", $model->architecture, "\n";
print "Tensors: ", $model->n_tensors, "\n";
print "KV pairs: ", $model->n_kv, "\n";

# Get model hyperparameters
print "\n=== Hyperparameters ===\n";
printf "  %-25s %s\n", "Context length:", $model->get_kv('llama.context_length');
printf "  %-25s %s\n", "Embedding dim:", $model->get_kv('llama.embedding_length');
printf "  %-25s %s\n", "Layers:", $model->get_kv('llama.block_count');
printf "  %-25s %s\n", "Attention heads:", $model->get_kv('llama.attention.head_count');
printf "  %-25s %s\n", "KV heads:", $model->get_kv('llama.attention.head_count_kv');
printf "  %-25s %s\n", "Feed-forward dim:", $model->get_kv('llama.feed_forward_length');
printf "  %-25s %s\n", "RoPE dimension:", $model->get_kv('llama.rope.dimension_count');
printf "  %-25s %s\n", "RoPE freq base:", $model->get_kv('llama.rope.freq_base');

# List some tensors
print "\n=== Model Tensors (first 10) ===\n";
my @tensors = $model->tensor_names;
print "  $_\n" for @tensors[0..9];
print "  ... and ", (scalar(@tensors) - 10), " more\n";

# Create tokenizer
print "\n=== Tokenizer ===\n";
my $tokenizer = Lugh::Tokenizer->new(model => $model);
print "Vocabulary size: ", $tokenizer->n_vocab, "\n";
print "BOS token ID: ", $tokenizer->bos_id, "\n";
print "EOS token ID: ", $tokenizer->eos_id, "\n";

# Tokenize some text
my $text = "Hello, how are you today?";
print "\nInput: \"$text\"\n";
my @tokens = $tokenizer->encode($text);
print "Tokens: @tokens\n";

my $decoded = $tokenizer->decode(@tokens);
print "Decoded: \"$decoded\"\n";

# Create inference engine
print "\n=== Inference Engine ===\n";
my $inference = Lugh::Inference->new(
    model => $model,
    n_ctx => 512,
    n_threads => 4
);

print "Context size: ", $inference->n_ctx, "\n";
print "Embedding dim: ", $inference->n_embd, "\n";
print "Layers: ", $inference->n_layer, "\n";
print "Attention heads: ", $inference->n_head, "\n";

# Basic tensor operations work too
print "\n=== Basic Tensor Operations ===\n";
my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
my $t1 = Lugh::Tensor->new_f32($ctx, 3);
my $t2 = Lugh::Tensor->new_f32($ctx, 3);

$t1->set_f32(1.0, 2.0, 3.0);
$t2->set_f32(4.0, 5.0, 6.0);

my $sum = Lugh::Ops::add($ctx, $t1, $t2);
my $graph = Lugh::Graph->new($ctx);
$graph->build_forward($sum);
$graph->compute($ctx, 4);

my @t1_vals = $t1->get_f32();
my @t2_vals = $t2->get_f32();
my @sum_vals = $sum->get_f32();
print "t1 = [", join(", ", @t1_vals), "]\n";
print "t2 = [", join(", ", @t2_vals), "]\n";
print "t1 + t2 = [", join(", ", @sum_vals), "]\n";

print "\n=== Summary ===\n";
print "Lugh provides:\n";
print "  - GGUF model loading (metadata, tensors)\n";
print "  - SentencePiece-compatible tokenization\n";
print "  - ggml tensor operations (add, mul_mat, etc.)\n";
print "  - Computation graph building and execution\n";
print "  - Thread-safe design with registry pattern\n";
print "\nNext steps to complete inference:\n";
print "  - Load model weights into ggml tensors\n";
print "  - Build transformer computation graph\n";
print "  - Implement KV cache for autoregressive generation\n";
print "  - Add sampling (greedy, top-k, top-p)\n";
