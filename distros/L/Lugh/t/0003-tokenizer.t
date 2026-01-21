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

plan tests => 26;

# Load model and create tokenizer
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');
isa_ok($tokenizer, 'Lugh::Tokenizer');

# Test vocabulary size
my $vocab_size = $tokenizer->n_vocab;
ok($vocab_size > 0, 'Vocabulary size is positive');
is($vocab_size, 2048, 'Vocabulary size is 2048');

# Test special token IDs
my $bos_id = $tokenizer->bos_id;
my $eos_id = $tokenizer->eos_id;
ok(defined $bos_id, 'BOS token ID defined');
ok(defined $eos_id, 'EOS token ID defined');
is($bos_id, 1, 'BOS token ID is 1');
is($eos_id, 2, 'EOS token ID is 2');

# Test basic encoding with BOS
my @tokens = $tokenizer->encode("Hello");
ok(scalar(@tokens) > 0, 'encode() returns tokens');
is($tokens[0], $bos_id, 'First token is BOS by default');

# Test encoding without BOS
my @tokens_no_bos = $tokenizer->encode("Hello", add_bos => 0);
ok(scalar(@tokens_no_bos) > 0, 'encode() without BOS returns tokens');
isnt($tokens_no_bos[0], $bos_id, 'First token is not BOS when add_bos => 0');

# Test encoding empty string
my @empty_tokens = $tokenizer->encode("");
ok(scalar(@empty_tokens) > 0, 'Empty string returns at least BOS token');
is($empty_tokens[0], $bos_id, 'Empty string starts with BOS');

# Test encoding simple phrases
my @capital_tokens = $tokenizer->encode("Once upon a time");
ok(scalar(@capital_tokens) > 1, 'Phrase encodes to multiple tokens');
is($capital_tokens[0], $bos_id, 'Phrase starts with BOS');

# Test decode
my $decoded = $tokenizer->decode([$bos_id]);
ok(defined $decoded, 'BOS token decodes');

# Test round-trip encoding/decoding
my $original = "Hello world";
my @encoded = $tokenizer->encode($original);
my $decoded_full = $tokenizer->decode(\@encoded);
like($decoded_full, qr/Hello/i, 'Round-trip preserves main content');
like($decoded_full, qr/world/i, 'Round-trip preserves all words');

# Test encoding with punctuation
my @punct_tokens = $tokenizer->encode("Hello, how are you?");
ok(scalar(@punct_tokens) > 3, 'Punctuation encoded');

# Test encoding with numbers
my @num_tokens = $tokenizer->encode("The year is 2024");
ok(scalar(@num_tokens) > 1, 'Numbers encoded');

# Test UTF-8 handling (basic ASCII)
my @ascii_tokens = $tokenizer->encode("ABC123");
ok(scalar(@ascii_tokens) > 0, 'ASCII text encodes');

# Test multiple sentences
my @multi_tokens = $tokenizer->encode("First sentence. Second sentence.");
ok(scalar(@multi_tokens) > 5, 'Multiple sentences encode');

# Test decode multiple tokens
my @sample_tokens = @capital_tokens[0..2];
my $sample_text = $tokenizer->decode(\@sample_tokens);
ok(defined $sample_text, 'Multiple token decode produces text');

# Test deterministic encoding
my @enc1 = $tokenizer->encode("Once upon a time");
my @enc2 = $tokenizer->encode("Once upon a time");
is_deeply(\@enc1, \@enc2, 'Same input produces same tokens (deterministic)');
