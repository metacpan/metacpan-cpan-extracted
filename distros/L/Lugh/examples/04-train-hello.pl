#!/usr/bin/env perl
# examples/train-simple.pl
#
# Train a model from scratch to memorize simple patterns.
# Uses heavy overfitting on minimal data to demonstrate training works.

use strict;
use warnings;
use FindBin;
use Time::HiRes qw(time);
$| = 1;

use Lugh;
use Lugh::Optimizer;
use Lugh::Train;

print "\n";
print "============================================================\n";
print "     Training from Scratch - Simple Memorization            \n";
print "============================================================\n\n";

# Create model with more capacity
my $model_path = "/tmp/simple-model.gguf";
print "Creating model...\n";

Lugh::Model->create(
    file    => $model_path,
    n_vocab => 256,      # Byte-level
    n_embd  => 128,      # Larger embedding
    n_layer => 4,        # More layers  
    n_head  => 8,
    n_ff    => 512,
    n_ctx   => 32,
);

my $model = Lugh::Model->new(model => $model_path);
my $inference = Lugh::Inference->new(model => $model);
print "Created model with ", $model->n_tensors(), " tensors\n\n";

# Get trainable weights
my $weight_ctx = Lugh::Context->new(size => 512 * 1024 * 1024);
my $weights_hash = $model->get_trainable_weights($weight_ctx);
delete $weights_hash->{_n_tensors};
delete $weights_hash->{_model_id};
my @weights = values %$weights_hash;
print "Got ", scalar(@weights), " trainable weights\n\n";

# Tokenization
sub tokenize { return (1, map { ord($_) } split //, $_[0]) }
sub detokenize { 
    my @chars = map { $_ > 31 && $_ < 127 ? chr($_) : '' } @_[1..$#_];
    return join '', @chars;
}

# Very simple data - just a few phrases to memorize
my @data = (
    "Hello",
    "Hello",
    "Hello",
    "Hello",
);

# Test generation (greedy)
sub generate {
    my ($prompt, $n) = @_;
    my @tokens = tokenize($prompt);
    for (1..$n) {
        my @logits = $inference->forward(tokens => \@tokens);
        my ($best, $max) = (0, $logits[0] // -999);
        for my $i (1..$#logits) {
            if (defined $logits[$i] && $logits[$i] > $max) {
                ($best, $max) = ($i, $logits[$i]);
            }
        }
        push @tokens, $best;
    }
    return detokenize(@tokens);
}

print "BEFORE training:\n";
print "  'H' -> '", generate("H", 5), "'\n\n";

# Optimizer with higher learning rate for memorization
my $optimizer = Lugh::Optimizer::AdamW->new(lr => 0.01, weight_decay => 0.0);
$optimizer->add_param($_) for @weights;

print "Training (5000 steps on 'Hello')...\n";
my $start = time();
my $last_loss = 0;

for my $epoch (1..5000) {
    my $text = $data[$epoch % scalar(@data)];
    my @tokens = tokenize($text);
    
    my @input = @tokens[0..$#tokens-1];
    my @target = @tokens[1..$#tokens];
    
    my $ctx = Lugh::Context->new(size => 32 * 1024 * 1024);
    $optimizer->zero_grad();
    
    my $logits = Lugh::Train->forward(
        inference => $inference,
        context   => $ctx,
        tokens    => \@input,
        train_lora => 0,
        train_full => 1,
    );
    
    Lugh::Train->register_weight_tensors($logits, \@weights);
    
    my $loss = Lugh::Train->cross_entropy_loss($ctx, $logits, \@target);
    my ($lv) = $loss->get_data();
    $last_loss = $lv;
    
    $loss->backward();
    $optimizer->step();
    
    if ($epoch % 500 == 0) {
        printf "  Epoch %4d: loss=%.4f\n", $epoch, $lv;
    }
}

printf "\nTraining completed in %.1f seconds\n", time() - $start;
printf "Final loss: %.4f\n\n", $last_loss;

print "AFTER training:\n";
print "  'H' -> '", generate("H", 4), "'\n"; # Hello
print "  'He' -> '", generate("He", 3), "'\n"; # Hello
print "  'Hel' -> '", generate("Hel", 2), "'\n"; # Hello
