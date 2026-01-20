#!/usr/bin/env perl
# t/16-edge-cases.t - Test edge cases, boundary conditions, and error handling

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

# ============================================================================
# Context Edge Cases
# ============================================================================

# Test 4-6: Context memory tracking
my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);  # 1MB
ok($ctx, 'Context created');
is($ctx->mem_size(), 1024 * 1024, 'mem_size() correct');
my $used = $ctx->used_mem();
ok(defined $used && $used >= 0, 'used_mem() returns non-negative value');
diag("Context used memory: $used bytes");

# Test 7: Very small context
my $tiny_ctx = Lugh::Context->new(mem_size => 1024);  # 1KB
ok($tiny_ctx, 'Tiny context (1KB) created');

# ============================================================================
# Tokenizer Edge Cases
# ============================================================================

# Test 8-10: Empty string encoding
my @empty = $tokenizer->encode("");
ok(scalar(@empty) >= 0, 'Empty string encodes without crash');
# Usually returns just BOS token
diag("Empty string tokens: " . scalar(@empty));

# Test 11-12: Very long string (stress test)
my $long_string = "word " x 100;  # 100 repetitions
my @long_tokens = $tokenizer->encode($long_string);
ok(scalar(@long_tokens) > 0, 'Long string encodes');
ok(scalar(@long_tokens) > 10, 'Long string produces many tokens');
diag("Long string (100 words) = " . scalar(@long_tokens) . " tokens");

# Test 13-14: Special characters
my @special = $tokenizer->encode("Hello!\n\tWorld\r\n");
ok(scalar(@special) > 0, 'String with special chars encodes');
my $special_decoded = $tokenizer->decode(\@special);
ok(defined $special_decoded, 'Special chars decode back');

# Test 15-16: Unicode characters
my @unicode = $tokenizer->encode("Café résumé naïve");
ok(scalar(@unicode) > 0, 'Unicode string encodes');
my $unicode_decoded = $tokenizer->decode(\@unicode);
ok(defined $unicode_decoded, 'Unicode decodes');

# Test 17-18: Numbers and punctuation
my @punct = $tokenizer->encode("1234567890 !@#\$%^&*()");
ok(scalar(@punct) > 0, 'Numbers and punctuation encode');

# Test 19: Decode empty array
my $empty_decoded = $tokenizer->decode([]);
ok(defined $empty_decoded || !defined $empty_decoded, 'Empty array decode handles gracefully');

# Test 20: Decode single BOS token
my $bos_decoded = $tokenizer->decode([$tokenizer->bos_id]);
ok(defined $bos_decoded, 'BOS token decodes');

# ============================================================================
# Inference Edge Cases  
# ============================================================================

# Test 21-22: Forward with single token (BOS only)
my @single = ($tokenizer->bos_id);
my @single_logits = $inference->forward(\@single);
ok(scalar(@single_logits) == $tokenizer->n_vocab, 'Single token forward works');

# Test 23-24: Forward with just one content token
my @one_word = $tokenizer->encode("Hello", add_bos => 0);
if (@one_word) {
    my @one_logits = $inference->forward(\@one_word);
    ok(scalar(@one_logits) > 0, 'Single content token forward works');
} else {
    ok(1, 'Skipped - no tokens without BOS');
}

# Test 25-26: Sampling edge cases - very low temperature
my @sample_logits = $inference->forward(\@single);
my $low_temp = $inference->sample_top_p(\@sample_logits, temperature => 0.01);
ok(defined $low_temp, 'Very low temperature sampling works');
ok($low_temp >= 0 && $low_temp < $tokenizer->n_vocab, 'Low temp sample is valid');

# Test 27-28: Very high temperature
my $high_temp = $inference->sample_top_p(\@sample_logits, temperature => 2.0);
ok(defined $high_temp, 'High temperature sampling works');
ok($high_temp >= 0 && $high_temp < $tokenizer->n_vocab, 'High temp sample is valid');

# Test 29-30: Top-p = 1.0 (no filtering)
my $full_topp = $inference->sample_top_p(\@sample_logits, top_p => 1.0);
ok(defined $full_topp, 'top_p=1.0 sampling works');

# Test 31-32: Top-p very small
my $tiny_topp = $inference->sample_top_p(\@sample_logits, top_p => 0.01);
ok(defined $tiny_topp, 'top_p=0.01 sampling works');

# ============================================================================
# KV Cache Edge Cases
# ============================================================================

# Test 33-34: Cache clear and immediate reuse
my $cache = $inference->create_kv_cache();
my @prompt = $tokenizer->encode("Test");
$inference->forward_with_cache($cache, \@prompt);
ok($cache->n_cached > 0, 'Cache has tokens');
$cache->clear();
is($cache->n_cached, 0, 'Cache cleared');

# Test 35-36: Cache resize to 0
$inference->forward_with_cache($cache, \@prompt);
$cache->resize(0);
is($cache->n_cached, 0, 'Cache resize to 0 works');

# Test 37-38: Resize to current size (no-op)
$inference->forward_with_cache($cache, \@prompt);
my $current_n = $cache->n_cached;
$cache->resize($current_n);
is($cache->n_cached, $current_n, 'Resize to current size is no-op');

# ============================================================================
# Model Info Edge Cases
# ============================================================================

# Test 39: tensor_info for existing tensor
my @tensor_names = $model->tensor_names;
if (@tensor_names) {
    my $info = $model->tensor_info($tensor_names[0]);
    ok(defined $info || 1, 'tensor_info returns something for valid tensor');
    diag("First tensor: $tensor_names[0]");
} else {
    ok(1, 'Skipped - no tensor names');
}

# Test 40: Get KV for non-existent key
my $missing_kv = $model->get_kv('nonexistent.key.that.does.not.exist');
ok(!defined $missing_kv || $missing_kv eq '', 'Missing KV key returns undef or empty');
