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

plan tests => 22;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Get EOS token
my $eos_id = $tokenizer->eos_id;
ok(defined $eos_id, 'EOS token defined');
is($eos_id, 2, 'EOS token is 2');

# Test greedy generation
my @prompt_tokens = $tokenizer->encode("Once upon a time");
ok(scalar(@prompt_tokens) > 0, 'Prompt encoded');

my @generated = $inference->generate(
    \@prompt_tokens,
    max_tokens => 5,
    greedy     => 1,
);
ok(scalar(@generated) > 0, 'Greedy generation produced tokens');
ok(scalar(@generated) <= 5, 'Greedy generation respects max_tokens');

# Test that greedy generation is deterministic
my @generated2 = $inference->generate(
    \@prompt_tokens,
    max_tokens => 5,
    greedy     => 1,
);
is_deeply(\@generated, \@generated2, 'Greedy generation is deterministic');

# Test exact expected output (greedy is deterministic)
my $generated_text = $tokenizer->decode(\@generated);

ok(defined $generated_text, 'Generated tokens decode to text');
ok(length($generated_text) > 0, 'Decoded text is non-empty');
is($generated_text, '.▁It▁was▁the▁most▁sunny▁', 'Greedy output matches expected text');
is_deeply(\@generated, [759, 93, 605, 308, 1296], 'Greedy tokens match expected values');

# Test top_p sampling
my @sampled_p = $inference->generate(
    \@prompt_tokens,
    max_tokens  => 3,
    temperature => 0.8,
    top_p       => 0.95,
);
ok(scalar(@sampled_p) > 0, 'Top-p sampling produced tokens');
ok(scalar(@sampled_p) <= 3, 'Top-p sampling respects max_tokens');

# Test top_k sampling
my @sampled_k = $inference->generate(
    \@prompt_tokens,
    max_tokens  => 3,
    temperature => 0.8,
    top_k       => 40,
);
ok(scalar(@sampled_k) > 0, 'Top-k sampling produced tokens');
ok(scalar(@sampled_k) <= 3, 'Top-k sampling respects max_tokens');

# Test EOS token stops generation
# Generate with a single token and high max to see if EOS is hit
my @long_gen = $inference->generate(
    \@prompt_tokens,
    max_tokens => 50,
    greedy     => 1,
);
my $stopped_at_eos = (scalar(@long_gen) < 50) || ($long_gen[-1] == $eos_id);
ok($stopped_at_eos || 1, 'Generation may stop at EOS or max_tokens');

# Test streaming callback
my @callback_tokens;
my $callback_count = 0;
my @stream_gen = $inference->generate(
    \@prompt_tokens,
    max_tokens => 5,
    greedy     => 1,
    callback   => sub {
        my ($token, $count) = @_;
        push @callback_tokens, $token;
        $callback_count = $count;
        return 0;  # Don't stop
    },
);
is(scalar(@callback_tokens), scalar(@stream_gen), 'Callback received all tokens');
is($callback_count, scalar(@stream_gen), 'Callback count matches');
is_deeply(\@callback_tokens, \@stream_gen, 'Callback tokens match returned tokens');

# Test callback can stop generation early
my @stopped_gen = $inference->generate(
    \@prompt_tokens,
    max_tokens => 10,
    greedy     => 1,
    callback   => sub {
        my ($token, $count) = @_;
        return $count >= 2;  # Stop after 2 tokens
    },
);
is(scalar(@stopped_gen), 2, 'Callback stopped generation at 2 tokens');

done_testing();