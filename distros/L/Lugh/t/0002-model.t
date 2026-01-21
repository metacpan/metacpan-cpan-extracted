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

plan tests => 13;

# Test Model loading
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model created');
isa_ok($model, 'Lugh::Model');

# Basic accessors
is($model->filename, $model_file, 'filename accessor works');
is($model->architecture, 'llama', 'architecture is llama');
ok($model->n_tensors > 0, 'has tensors');
ok($model->n_kv > 0, 'has kv pairs');

# Tensor names
my @tensors = $model->tensor_names;
ok(scalar(@tensors) > 0, 'got tensor names');
ok(grep { /token_embd/ } @tensors, 'has embedding tensor');
ok(grep { /blk\.0\.attn/ } @tensors, 'has attention tensors');

# KV metadata
my @keys = $model->kv_keys;
ok(scalar(@keys) > 0, 'got kv keys');
ok(grep { /general\.architecture/ } @keys, 'has architecture key');

# Get context length (varies by model)
my $ctx_len = $model->get_kv('llama.context_length');
ok(defined $ctx_len && $ctx_len > 0, 'context length is set');

my $block_count = $model->get_kv('llama.block_count');
ok(defined $block_count && $block_count > 0, 'has transformer blocks');

done_testing();
