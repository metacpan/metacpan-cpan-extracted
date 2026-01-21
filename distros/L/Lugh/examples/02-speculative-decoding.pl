#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch";

use Lugh;
use Lugh::Model;
use Lugh::Tokenizer;
use Lugh::Inference;
use Lugh::Speculative;
use Time::HiRes qw(time);

=head1 NAME

02-speculative-decoding.pl - Demonstrate speculative decoding for faster text generation

=head1 SYNOPSIS

    # First download the models:
    perl download-model.pl --model tinyllama-q2   # Draft model (faster quant)
    perl download-model.pl --model tinyllama-q4   # Main model (better quality)
    
    # Then run this example:
    perl 02-speculative-decoding.pl

=head1 DESCRIPTION

Speculative decoding uses a small "draft" model to propose tokens quickly,
then verifies them with a larger "main" model. When draft tokens match what
the main model would have generated, we get multiple tokens per main model
forward pass, resulting in faster generation.

Requirements:
- Draft and main models must share the same vocabulary (tokenizer)
- Draft model should be significantly faster than main model

Note: Using same-size models (different quantizations) demonstrates the
feature but won't show speedup - the overhead outweighs the benefit.
For real speedup, use a smaller draft model (e.g., 125M vs 7B).

=cut

# Model paths - adjust these to your downloaded models
my $MODEL_DIR = "$Bin/../models";

# Recommended pairings (same vocabulary):
#   tinyllama-q2 (draft) + tinyllama-q4 (main) - same model, different quants
#   qwen2-0.5b-q4 (draft) + qwen2-1.5b-q4 (main) - different sizes

my $DRAFT_MODEL = "$MODEL_DIR/tinyllama-1.1b-chat-v1.0.Q2_K.gguf";
my $MAIN_MODEL  = "$MODEL_DIR/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf";

# Check models exist
unless (-f $DRAFT_MODEL) {
    die "Draft model not found: $DRAFT_MODEL\n" .
        "Run: perl download-model.pl --model tinyllama-q2\n";
}
unless (-f $MAIN_MODEL) {
    die "Main model not found: $MAIN_MODEL\n" .
        "Run: perl download-model.pl --model tinyllama-q4\n";
}

print "=" x 60, "\n";
print "Speculative Decoding Demo\n";
print "=" x 60, "\n\n";

print "Loading models...\n";
print "  Draft: $DRAFT_MODEL\n";
print "  Main:  $MAIN_MODEL\n\n";

# Load both models
my $draft_model = Lugh::Model->new(model => $DRAFT_MODEL);
my $main_model  = Lugh::Model->new(model => $MAIN_MODEL);

# Create tokenizer (use main model's tokenizer - they should be compatible)
my $tokenizer = Lugh::Tokenizer->new(model => $main_model);

# Create inference engines
# Note: We create separate inference objects for standard generation and speculative
# to avoid state pollution (KV cache, position tracking)
my $draft_inf = Lugh::Inference->new(model => $draft_model, n_ctx => 512, n_threads => 4);
my $main_inf  = Lugh::Inference->new(model => $main_model, n_ctx => 512, n_threads => 4);
my $main_inf_spec = Lugh::Inference->new(model => $main_model, n_ctx => 512, n_threads => 4);

print "Draft model: ", $draft_model->architecture, "\n";
print "Main model:  ", $main_model->architecture, "\n";
print "Vocabulary size: ", $tokenizer->n_vocab, "\n\n";

# Create speculative decoder with its own main inference
my $spec = Lugh::Speculative->new(
    inference => $main_inf_spec,  # Separate inference object
    draft     => $draft_inf,      # Draft model (smaller, faster)
    k         => 4,               # Number of draft tokens per step
    temperature => 0.8,
    top_p       => 0.95,
);

# Test prompt
my $prompt = "The future of artificial intelligence is";
my $max_tokens = 30;
my $draft_k = 4;  # Number of tokens to draft at each step

print "Prompt: \"$prompt\"\n";
print "Max tokens: $max_tokens, Draft K: $draft_k\n";
print "-" x 60, "\n\n";

# Tokenize prompt
my @prompt_tokens = $tokenizer->encode($prompt);
print "Prompt tokens: @prompt_tokens\n\n";

# ============================================================
# Method 1: Standard generation (main model only) for baseline
# ============================================================
print "1. Standard Generation (main model only):\n";
print "-" x 40, "\n";

my $start = time();
my @tokens = @prompt_tokens;
my @generated_standard;

for my $i (1..$max_tokens) {
    my @logits = $main_inf->forward(tokens => \@tokens);
    my $next_token = $main_inf->sample_top_p(\@logits, temperature => 0.8, top_p => 0.95);
    push @tokens, $next_token;
    push @generated_standard, $next_token;
    
    # Stop on EOS
    last if $next_token == $tokenizer->eos_id;
}

my $elapsed_standard = time() - $start;
my $text_standard = $tokenizer->decode(@generated_standard);

print "Generated: $text_standard\n";
print sprintf("Time: %.2fs (%.1f tokens/sec)\n\n", 
    $elapsed_standard, 
    scalar(@generated_standard) / $elapsed_standard);

# ============================================================
# Method 2: Speculative decoding
# ============================================================
print "2. Speculative Decoding:\n";
print "-" x 40, "\n";

# Seed C RNG for reproducible draft sampling
Lugh::srand(42);

$start = time();
my $generated_spec = $spec->generate(\@prompt_tokens, $max_tokens);

my $elapsed_spec = time() - $start;
my $text_spec = $tokenizer->decode($generated_spec);
my $acceptance_rate = $spec->acceptance_rate * 100;
my $total_drafted = $spec->tokens_drafted;
my $total_accepted = $spec->tokens_accepted;

print "Generated: $text_spec\n";
print sprintf("Time: %.2fs (%.1f tokens/sec)\n", 
    $elapsed_spec,
    scalar(@$generated_spec) / ($elapsed_spec || 0.001));
print sprintf("Acceptance rate: %.1f%% (%d/%d drafted tokens)\n\n",
    $acceptance_rate, $total_accepted, $total_drafted);

# ============================================================
# Summary
# ============================================================
print "=" x 60, "\n";
print "Summary:\n";
print "=" x 60, "\n";
my $speedup = $elapsed_standard / $elapsed_spec;
print sprintf("Standard: %.2fs, Speculative: %.2fs\n", $elapsed_standard, $elapsed_spec);
print sprintf("Speedup: %.2fx\n", $speedup);
print sprintf("Acceptance rate: %.1f%%\n", $acceptance_rate);

if ($speedup > 1) {
    print "\n✓ Speculative decoding was faster!\n";
} else {
    print "\n✗ Standard generation was faster.\n";
    print "   Note: For speedup, draft model must be significantly smaller/faster.\n";
    print "   Using same-size models with different quantizations shows overhead.\n";
    print "   Try: small draft (e.g., 125M) + large main (e.g., 7B) for real gains.\n";
}
