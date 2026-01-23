#!/usr/bin/env perl
#
# Lugh - LoRA Training Example
#
# This example demonstrates creating, training, and saving LoRA adapters.
# LoRA (Low-Rank Adaptation) enables efficient fine-tuning by adding small
# trainable matrices to frozen model weights.
#

use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Lugh;

# Configuration
my $model_path = $ARGV[0] // 'models/tinyllama-1.1b-chat-v1.0.Q2_K.gguf';
my $output_path = 'my-lora-adapter.gguf';

die "Usage: $0 <model.gguf>\n" unless -f $model_path;

print "=" x 60, "\n";
print "Lugh LoRA Training Example\n";
print "=" x 60, "\n\n";

# Step 1: Load the base model
print "Loading base model: $model_path\n";
my $model = Lugh::Model->new(file => $model_path);
print "  Architecture: ", $model->architecture, "\n";
print "  Tensors: ", $model->n_tensors, "\n\n";

# Step 2: Create a trainable LoRA adapter
print "Creating trainable LoRA adapter...\n";
my $lora = Lugh::LoRA->create(
    model   => $model,
    rank    => 8,                          # Low rank for efficiency
    alpha   => 16.0,                       # Scaling factor
    targets => [qw(attn_q attn_v)],        # Target attention Q and V projections
);

print "  Format: ", $lora->format, "\n";
print "  Trainable: ", ($lora->trainable ? "yes" : "no"), "\n";
print "  Alpha: ", $lora->alpha, "\n";
print "  Scale: ", $lora->scale, "\n";
print "  Weight pairs: ", $lora->n_weights, "\n\n";

# Step 3: Examine the weight structure
print "LoRA weight names (first 5):\n";
my @names = $lora->weight_names;
for my $i (0 .. 4) {
    last unless defined $names[$i];
    print "  $names[$i]\n";
}
print "  ... and ", (scalar(@names) - 5), " more\n\n" if @names > 5;

# Step 4: Access weight tensors for training
print "Accessing trainable tensors...\n";
my $first_weight = $names[0];
my $tensor_a = $lora->get_weight_tensor($first_weight, 'a');
my $tensor_b = $lora->get_weight_tensor($first_weight, 'b');

print "  Weight: $first_weight\n";
print "  Tensor A (down-projection):\n";
print "    - ID: ", $tensor_a->id, "\n";
print "    - Elements: ", $tensor_a->nelements, "\n";
print "    - Requires grad: ", ($tensor_a->requires_grad ? "yes" : "no"), "\n";

print "  Tensor B (up-projection):\n";
print "    - ID: ", $tensor_b->id, "\n";
print "    - Elements: ", $tensor_b->nelements, "\n";
print "    - Requires grad: ", ($tensor_b->requires_grad ? "yes" : "no"), "\n\n";

# Step 5: Demonstrate initialization
print "Weight initialization:\n";
my @a_data = $tensor_a->get_data;
my @b_data = $tensor_b->get_data;

my $a_nonzero = grep { $_ != 0 } @a_data;
my $b_nonzero = grep { $_ != 0 } @b_data;

print "  A matrix: ", scalar(@a_data), " elements, $a_nonzero non-zero (Kaiming init)\n";
print "  B matrix: ", scalar(@b_data), " elements, $b_nonzero non-zero (zero init)\n\n";

# Step 6: Access gradients
print "Gradient access:\n";
my $grad = $tensor_a->grad;
if (defined $grad) {
    my $grad_sum = 0;
    $grad_sum += abs($_) for @$grad;
    print "  Gradient elements: ", scalar(@$grad), "\n";
    print "  Gradient sum: $grad_sum (should be 0 before training)\n\n";
} else {
    print "  No gradient allocated yet\n\n";
}

# Step 7: Simulate a training step (in real training, you'd compute gradients)
print "Simulating training...\n";
print "  In a real training loop, you would:\n";
print "    1. Forward pass through the model with LoRA\n";
print "    2. Compute loss (e.g., cross-entropy)\n";
print "    3. Backward pass to compute gradients\n";
print "    4. Update weights using an optimizer (AdamW, SGD)\n";
print "    5. Repeat for each batch\n\n";

# Step 8: Adjust LoRA scaling
print "Adjusting LoRA scale:\n";
print "  Original scale: ", $lora->scale, "\n";
$lora->scale(0.5);
print "  New scale: ", $lora->scale, " (half strength)\n";
$lora->scale(1.0);
print "  Reset to: ", $lora->scale, "\n\n";

# Step 9: Save the adapter
print "Saving LoRA adapter to: $output_path\n";
$lora->save($output_path);
print "  File size: ", -s $output_path, " bytes\n\n";

# Step 10: Verify the saved adapter can be loaded
print "Verifying saved adapter...\n";
my $loaded = Lugh::LoRA->new(
    adapter => $output_path,
    model   => $model,
);
print "  Loaded format: ", $loaded->format, "\n";
print "  Loaded weights: ", $loaded->n_weights, "\n";
print "  Loaded alpha: ", $loaded->alpha, "\n";
print "  Trainable: ", ($loaded->trainable ? "yes" : "no"), " (loaded adapters are not trainable)\n\n";

# Cleanup
unlink $output_path;

print "=" x 60, "\n";
print "LoRA training example complete!\n";
print "=" x 60, "\n";

__END__

=head1 NAME

03-lora-training.pl - LoRA Training Example for Lugh

=head1 SYNOPSIS

    perl examples/03-lora-training.pl [model.gguf]

=head1 DESCRIPTION

This example demonstrates the complete workflow for LoRA (Low-Rank Adaptation)
training with Lugh:

=over 4

=item 1. Load a base GGUF model

=item 2. Create a trainable LoRA adapter with specified rank and targets

=item 3. Access weight tensors as Lugh::Autograd::Tensor objects

=item 4. Examine initialization (Kaiming for A, zeros for B)

=item 5. Access gradient tensors for training

=item 6. Save the trained adapter to GGUF format

=item 7. Reload and verify the saved adapter

=back

=head1 LORA PARAMETERS

=over 4

=item B<rank>

The rank of the low-rank decomposition. Lower values (4, 8) use less memory
but have less expressiveness. Higher values (32, 64) can capture more complex
adaptations. Common choices: 4, 8, 16, 32.

=item B<alpha>

Scaling factor applied to the LoRA output. The effective scale is
C<alpha / rank>. Typical value: 2 * rank (e.g., alpha=16 for rank=8).

=item B<targets>

Which layers to add LoRA adapters to:

    attn_q      - Query projection (recommended)
    attn_k      - Key projection
    attn_v      - Value projection (recommended)
    attn_output - Output projection
    ffn_up      - FFN up projection
    ffn_down    - FFN down projection
    ffn_gate    - FFN gate (SwiGLU models)

=back

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=cut
