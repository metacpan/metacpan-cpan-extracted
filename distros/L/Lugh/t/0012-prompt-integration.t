#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin;
use Lugh;
use Lugh::Prompt;

# Use bundled test model
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

# Get architecture from model
my $arch = $model->architecture // 'llama';
ok(defined $arch, "Model architecture: $arch");

# Test 1: Format detection for architecture
my $detected_format = Lugh::Prompt->format_for_architecture($arch);
ok($detected_format, "Detected format for $arch: $detected_format");
is($detected_format, 'llama2', 'Llama architecture uses llama2 format');

# Test 2: Simple user message with ChatML
my $chat_chatml = Lugh::Prompt->new(format => 'chatml');
my $prompt_chatml = $chat_chatml->apply(
    { role => 'user', content => 'Once upon a time' }
);
ok($prompt_chatml, 'ChatML prompt generated');
like($prompt_chatml, qr/<\|im_start\|>user/, 'ChatML has user tag');
like($prompt_chatml, qr/<\|im_start\|>assistant/, 'ChatML has assistant prompt');

# Test 3: Tokenize ChatML prompt and generate
my @tokens_chatml = $tokenizer->encode($prompt_chatml);
ok(scalar(@tokens_chatml) > 0, 'ChatML prompt tokenized');

my @gen_chatml = $inference->generate(
    \@tokens_chatml,
    max_tokens => 5,
    greedy     => 1,
);
ok(scalar(@gen_chatml) > 0, 'Generated tokens from ChatML prompt');
my $output_chatml = $tokenizer->decode(\@gen_chatml);
ok(defined $output_chatml, "ChatML output: $output_chatml");

# Test 4: Llama 2 format with system message
my $chat_llama2 = Lugh::Prompt->new(format => 'llama2');
my $prompt_llama2 = $chat_llama2->apply(
    { role => 'system', content => 'You are a helpful assistant.' },
    { role => 'user', content => 'Tell me a story' }
);
ok($prompt_llama2, 'Llama2 prompt generated');
like($prompt_llama2, qr/<<SYS>>/, 'Llama2 has system tag');
like($prompt_llama2, qr/\[INST\]/, 'Llama2 has INST tag');

# Tokenize and generate
my @tokens_llama2 = $tokenizer->encode($prompt_llama2);
ok(scalar(@tokens_llama2) > 0, 'Llama2 prompt tokenized');

my @gen_llama2 = $inference->generate(
    \@tokens_llama2,
    max_tokens => 5,
    greedy     => 1,
);
my $output_llama2 = $tokenizer->decode(\@gen_llama2);
ok(defined $output_llama2, "Llama2 output: $output_llama2");

# Test 5: Llama 3 format  
my $chat_llama3 = Lugh::Prompt->new(format => 'llama3');
my $prompt_llama3 = $chat_llama3->apply(
    { role => 'user', content => 'Once upon a time' }
);
ok($prompt_llama3, 'Llama3 prompt generated');
like($prompt_llama3, qr/<\|begin_of_text\|>/, 'Llama3 has BOS token');

my @tokens_llama3 = $tokenizer->encode($prompt_llama3);
my @gen_llama3 = $inference->generate(
    \@tokens_llama3,
    max_tokens => 5,
    greedy     => 1,
);
my $output_llama3 = $tokenizer->decode(\@gen_llama3);
ok(defined $output_llama3, "Llama3 output: $output_llama3");

# Test 6: Multi-turn conversation
my $chat_multi = Lugh::Prompt->new(format => 'chatml');
my $prompt_multi = $chat_multi->apply(
    { role => 'user', content => 'Hello' },
    { role => 'assistant', content => 'Hi there!' },
    { role => 'user', content => 'Tell me a story' }
);
ok($prompt_multi, 'Multi-turn prompt generated');

# Count role tags
my @user_tags = ($prompt_multi =~ /<\|im_start\|>user/g);
is(scalar(@user_tags), 2, 'Multi-turn has 2 user messages');
my @assistant_tags = ($prompt_multi =~ /<\|im_start\|>assistant/g);
is(scalar(@assistant_tags), 2, 'Multi-turn has 2 assistant tags (1 history + 1 prompt)');

# Test 7: Raw format (no formatting) - just the raw prompt
my $prompt_raw = "Once upon a time";
my @tokens_raw = $tokenizer->encode($prompt_raw);
my @gen_raw = $inference->generate(
    \@tokens_raw,
    max_tokens => 5,
    greedy     => 1,
);
my $output_raw = $tokenizer->decode(\@gen_raw);
# This should match the known deterministic output from 07-generate.t
is($output_raw, '.▁It▁was▁the▁most▁sunny▁', 'Raw format deterministic output matches expected');
is_deeply(\@gen_raw, [759, 93, 605, 308, 1296], 'Raw format tokens match expected');

# Test 8: Auto-detect format from model
my $chat_auto = Lugh::Prompt->new(model => $model);
my $prompt_auto = $chat_auto->apply(
    { role => 'user', content => 'Hello' }
);
ok($prompt_auto, "Auto-detected format works");
is($chat_auto->format_name, 'llama2', 'Auto-detected format is llama2 for llama arch');

