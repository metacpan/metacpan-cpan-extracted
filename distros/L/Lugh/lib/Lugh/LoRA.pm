package Lugh::LoRA;

use strict;
use warnings;
use Lugh;

our $VERSION = '0.12';

=head1 NAME

Lugh::LoRA - Low-Rank Adaptation (LoRA) adapter support for Lugh

=head1 SYNOPSIS

    use Lugh;
    
    # Load base model first
    my $model = Lugh::Model->new(file => 'base-model.gguf');
    
    # Load a LoRA adapter (GGUF format)
    my $lora = Lugh::LoRA->new(
        adapter => 'adapter.gguf',
        model   => $model,    # Required: validates architecture match
    );
    
    # Load a LoRA adapter (SafeTensors format)  
    my $lora = Lugh::LoRA->new(
        adapter => 'adapter.safetensors',
        model   => $model,
    );
    
    # Create a trainable LoRA adapter (for fine-tuning)
    my $trainable_lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 16,              # LoRA rank (default: 16)
        alpha   => 32.0,            # Scaling factor (default: 32.0)
        targets => [qw(attn_q attn_v)],  # Which layers to adapt
    );
    
    # Check adapter properties
    say "Alpha: ", $lora->alpha;
    say "Scale: ", $lora->scale;
    say "Weights: ", $lora->n_weights;
    say "Format: ", $lora->format;
    say "Trainable: ", $lora->trainable ? "yes" : "no";
    
    # Adjust the LoRA scaling factor
    $lora->scale(0.5);  # Half strength
    
    # Get weight names
    my @names = $lora->weight_names;
    
    # Access trainable weight tensors for gradient-based training
    my $tensor_a = $trainable_lora->get_weight_tensor('blk.0.attn_q.weight', 'a');
    my $tensor_b = $trainable_lora->get_weight_tensor('blk.0.attn_q.weight', 'b');
    
    # Save trained adapter to GGUF format
    $trainable_lora->save('my-finetuned-adapter.gguf');
    
    # Use with inference
    my $inference = Lugh::Inference->new(model => $model);
    my @logits = $inference->forward(tokens => \@tokens, lora => $lora);

=head1 DESCRIPTION

Lugh::LoRA provides support for loading, creating, training, and saving 
Low-Rank Adaptation (LoRA) adapters for base models. LoRA is an efficient 
fine-tuning technique that adds small rank-decomposition weight matrices 
to frozen pre-trained models.

The modified output is computed as:

    output = original_output + (alpha / rank) * scale * B @ A @ x

Where:

=over 4

=item * C<A> and C<B> are the low-rank LoRA matrices

=item * C<alpha> is the scaling factor from the adapter metadata

=item * C<rank> is the inner dimension of the decomposition

=item * C<scale> is a user-adjustable multiplier (default 1.0)

=back

=head1 TRAINABLE LORA

Lugh supports creating trainable LoRA adapters from scratch for fine-tuning:

    my $lora = Lugh::LoRA->create(
        model   => $model,
        rank    => 16,
        alpha   => 32.0,
        targets => [qw(attn_q attn_v)],
    );

Trainable LoRA adapters:

=over 4

=item * Have C<requires_grad> enabled on all weight tensors

=item * Include pre-allocated gradient tensors for backpropagation

=item * Use standard LoRA initialization (A: Kaiming, B: zeros)

=item * Can be saved to GGUF format after training

=back

=head2 Target Layers

The C<targets> parameter specifies which layers to add LoRA adapters to.
Supported targets include:

=over 4

=item * C<attn_q> - Query projection (default)

=item * C<attn_k> - Key projection

=item * C<attn_v> - Value projection (default)

=item * C<attn_output> - Output projection

=item * C<ffn_up> - FFN up projection

=item * C<ffn_down> - FFN down projection

=item * C<ffn_gate> - FFN gate projection (SwiGLU models)

=back

=head1 SUPPORTED FORMATS

=head2 GGUF Format

The native format for Lugh. GGUF LoRA files contain:

=over 4

=item * Metadata indicating this is a LoRA adapter (C<general.type = "adapter">)

=item * The LoRA alpha value (C<adapter.lora.alpha>)

=item * Architecture information for validation

=item * Paired LoRA tensors (C<*.lora_a>, C<*.lora_b>)

=back

GGUF adapters provide architecture validation - the adapter's architecture
must match the base model to ensure compatibility.

=head2 SafeTensors Format

The HuggingFace format for storing tensor data. SafeTensors files contain:

=over 4

=item * A JSON header with tensor metadata (names, shapes, offsets)

=item * Raw tensor data in little-endian format

=back

SafeTensors LoRA files typically use HuggingFace naming conventions which
are automatically translated to the internal format:

    base_model.model.layers.0.self_attn.q_proj.lora_A.weight
    -> blk.0.attn_q.weight

Note: SafeTensors format does not include alpha metadata, so you may need
to set it manually via the C<alpha> accessor or by checking the adapter's
original config.json.

=head1 METHODS

=head2 new

    my $lora = Lugh::LoRA->new(
        adapter => $path,     # Required: path to LoRA file
        model   => $model,    # Required: Lugh::Model for architecture validation
        scale   => $scale,    # Optional: scaling factor (default 1.0)
    );

Creates a new LoRA adapter from a GGUF or SafeTensors file. The file format
is automatically detected from the file extension.

The C<model> parameter is required because LoRA adapters must be validated
against the base model's architecture to ensure compatibility. The adapter's
layer names and tensor shapes must match the base model.

Note: The C<file> parameter is also accepted as an alias for C<adapter>.

=head2 alpha

    my $alpha = $lora->alpha;
    $lora->alpha(32.0);

Get or set the alpha scaling factor. This is typically set from the adapter
metadata but can be overridden for SafeTensors files or experimentation.

=head2 scale

    my $scale = $lora->scale;
    $lora->scale(0.5);

Get or set the user scale multiplier. The effective scaling is C<alpha * scale / rank>.
Use this to adjust LoRA influence without changing alpha.

Common values:

=over 4

=item * C<1.0> - Full LoRA effect (default)

=item * C<0.5> - Half LoRA effect

=item * C<0.0> - Disable LoRA (base model only)

=item * C<2.0> - Double LoRA effect (may cause instability)

=back

=head2 n_weights

    my $count = $lora->n_weights;

Returns the number of LoRA weight pairs in the adapter. Each weight pair
consists of an A matrix and a B matrix.

=head2 format

    my $fmt = $lora->format;

Returns the source format of the adapter: "gguf", "safetensors", or "trainable".

=head2 weight_names

    my @names = $lora->weight_names;

Returns the list of tensor names that have LoRA adaptations. Names are in
the internal format (e.g., "blk.0.attn_q.weight").

=head2 trainable

    my $is_trainable = $lora->trainable;

Returns true if this is a trainable LoRA adapter created with C<create()>,
false if it was loaded from a file with C<new()>.

=head2 create

    my $lora = Lugh::LoRA->create(
        model   => $model,     # Required: Lugh::Model
        rank    => $rank,      # Optional: LoRA rank (default: 16)
        alpha   => $alpha,     # Optional: scaling factor (default: 32.0)
        scale   => $scale,     # Optional: user scale (default: 1.0)
        targets => \@targets,  # Optional: layers to adapt
        context => $ctx,       # Optional: Lugh::Context for tensors
    );

Creates a new trainable LoRA adapter. Unlike C<new()>, this creates fresh
weight matrices initialized for training rather than loading from a file.

The C<rank> parameter controls the size of the low-rank decomposition.
Common values are 4, 8, 16, 32, or 64. Lower ranks use less memory but
have less expressiveness. Valid range: 1-256.

=head2 get_weight_tensor

    my $tensor_a = $lora->get_weight_tensor($name, 'a');
    my $tensor_b = $lora->get_weight_tensor($name, 'b');

Returns the LoRA weight tensor as a C<Lugh::Autograd::Tensor> object.
Only available on trainable adapters (created with C<create()>).

The C<$name> parameter is the base weight name (e.g., "blk.0.attn_q.weight").
The second parameter specifies which matrix: 'a' for the down-projection
or 'b' for the up-projection.

The returned tensor has C<requires_grad> enabled and gradient storage
allocated for use with backpropagation.

=head2 save

    $lora->save('my-adapter.gguf');

Saves the LoRA adapter to a GGUF file. The path must end with C<.gguf>.

The saved file includes:

=over 4

=item * Metadata: general.type, adapter.type, adapter.lora.alpha

=item * Architecture information (if available)

=item * All LoRA tensor pairs (*.lora_a, *.lora_b)

=back

The saved adapter can be loaded with C<new()> for inference.

=head1 USING LORA WITH INFERENCE

LoRA adapters integrate with all forward methods:

=head2 Basic Forward

    my @logits = $inference->forward(
        tokens => \@tokens,
        lora   => $lora,
    );

=head2 With KV Cache

    my $cache = $inference->create_kv_cache();
    my @logits = $inference->forward_cache(
        cache  => $cache,
        tokens => \@tokens,
        lora   => $lora,
    );

=head2 With Memory Pool

    my $pool = $inference->create_memory_pool();
    my @logits = $inference->forward_pool(
        pool   => $pool,
        tokens => \@tokens,
        lora   => $lora,
    );

=head2 Batch Processing

    my $results = $inference->forward_batch(
        sequences => [\@seq1, \@seq2, \@seq3],
        lora      => $lora,
    );

=head2 Adjusting LoRA Strength

Use the C<scale> property to adjust LoRA influence:

    $lora->scale(0.0);  # Disable LoRA (base model only)
    $lora->scale(0.5);  # Half LoRA effect
    $lora->scale(1.0);  # Full LoRA effect (default)
    $lora->scale(2.0);  # Double LoRA effect

=head1 SEE ALSO

L<Lugh>, L<Lugh::Inference>, L<Lugh::KVCache>, L<Lugh::Autograd::Tensor>

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
