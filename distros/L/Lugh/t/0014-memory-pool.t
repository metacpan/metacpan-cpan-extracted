#!/usr/bin/env perl
# t/14-memory-pool.t - Test memory pool functionality

use strict;
use warnings;
use Test::More;
use FindBin;

use Lugh;

my $model_file = "$FindBin::Bin/data/test-model.gguf";
unless (-e $model_file) {
    plan skip_all => "No test model at $model_file";
}

plan tests => 21;

# Load model and create components
my $model = Lugh::Model->new(model => $model_file);
ok($model, 'Model loaded');

my $tokenizer = Lugh::Tokenizer->new(model => $model);
ok($tokenizer, 'Tokenizer created');

my $inference = Lugh::Inference->new(model => $model);
ok($inference, 'Inference engine created');

# Test 4-6: Create memory pool
my $pool = $inference->create_memory_pool();
ok($pool, 'Memory pool created');
isa_ok($pool, 'Lugh::MemoryPool', 'Pool is correct type') 
    || diag("Pool type: " . ref($pool));

# Test 7: Encode a prompt
my @tokens = $tokenizer->encode("Once upon a time");
ok(scalar(@tokens) > 0, 'Prompt encoded');

# Test 8-10: Forward with pool
my @logits = $inference->forward_pool($pool, \@tokens);
ok(scalar(@logits) > 0, 'forward_pool returns logits');
is(scalar(@logits), $tokenizer->n_vocab, 'Logits size equals vocab size');

# Test logits are numeric
my $all_numeric = 1;
for my $l (@logits[0..9]) {
    unless (defined $l && $l =~ /^-?\d+\.?\d*(?:[eE][+-]?\d+)?$/) {
        $all_numeric = 0;
        last;
    }
}
ok($all_numeric, 'Logits are numeric values');

# Test 11-13: Compare pool vs non-pool results
my @logits_standard = $inference->forward_simple(\@tokens);
my $pool2 = $inference->create_memory_pool();
my @logits_pool2 = $inference->forward_pool($pool2, \@tokens);

# Find argmax for both
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

my $standard_pred = argmax(\@logits_standard);
my $pool_pred = argmax(\@logits_pool2);
is($pool_pred, $standard_pred, 'Pool forward agrees with standard forward on top prediction');

# Test 14-15: Reuse pool for multiple forwards
my @tokens2 = $tokenizer->encode("The quick brown fox");
my @logits_reuse = $inference->forward_pool($pool, \@tokens2);
ok(scalar(@logits_reuse) > 0, 'Pool can be reused for different input');
is(scalar(@logits_reuse), $tokenizer->n_vocab, 'Reused pool produces correct logits size');

# Test 16-18: Pool works with different length inputs
my @short_tokens = $tokenizer->encode("Hi");
my @logits_short = $inference->forward_pool($pool, \@short_tokens);
ok(scalar(@logits_short) > 0, 'Pool handles short input');

my @long_tokens = $tokenizer->encode("Once upon a time in a land far far away there lived");
my @logits_long = $inference->forward_pool($pool, \@long_tokens);
ok(scalar(@logits_long) > 0, 'Pool handles longer input');

is(scalar(@logits_short), scalar(@logits_long), 'Logits size consistent regardless of input length');

# Test 19-21: Multiple pools can coexist
my $pool_a = $inference->create_memory_pool();
my $pool_b = $inference->create_memory_pool();
ok($pool_a && $pool_b, 'Multiple pools created');

my @logits_a = $inference->forward_pool($pool_a, \@tokens);
my @logits_b = $inference->forward_pool($pool_b, \@tokens);

my $pred_a = argmax(\@logits_a);
my $pred_b = argmax(\@logits_b);
is($pred_a, $pred_b, 'Different pools produce same predictions');

# Test 22-25: Pool with generation sampling
my $sampled = $inference->sample_top_p(\@logits, temperature => 0.8);
ok(defined $sampled, 'Can sample from pool-generated logits');
ok($sampled >= 0 && $sampled < $tokenizer->n_vocab, 'Sampled token is valid');

my $decoded = $tokenizer->decode([$sampled]);
ok(defined $decoded, 'Sampled token decodes successfully');

# Verify pool results can be used for continued generation
push @tokens, $sampled;
my @next_logits = $inference->forward_pool($pool, \@tokens);
ok(scalar(@next_logits) > 0, 'Pool works for incremental generation');
