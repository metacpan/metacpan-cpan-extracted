package Lugh::LoRA;

use strict;
use warnings;
use Lugh;

our $VERSION = '0.11';

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
    
    # Check adapter properties
    say "Alpha: ", $lora->alpha;
    say "Scale: ", $lora->scale;
    say "Weights: ", $lora->n_weights;
    say "Format: ", $lora->format;
    
    # Adjust the LoRA scaling factor
    $lora->scale(0.5);  # Half strength
    
    # Get weight names
    my @names = $lora->weight_names;
    
    # Use with inference
    my $inference = Lugh::Inference->new(model => $model);
    my @logits = $inference->forward(tokens => \@tokens, lora => $lora);

=head1 DESCRIPTION

Lugh::LoRA provides support for loading and applying Low-Rank Adaptation (LoRA)
adapters to base models. LoRA is an efficient fine-tuning technique that adds
small rank-decomposition weight matrices to frozen pre-trained models.

The modified output is computed as:

    output = original_output + (alpha / rank) * scale * B @ A @ x

Where:

=over 4

=item * C<A> and C<B> are the low-rank LoRA matrices

=item * C<alpha> is the scaling factor from the adapter metadata

=item * C<rank> is the inner dimension of the decomposition

=item * C<scale> is a user-adjustable multiplier (default 1.0)

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

Returns the source format of the adapter: "gguf" or "safetensors".

=head2 weight_names

    my @names = $lora->weight_names;

Returns the list of tensor names that have LoRA adaptations. Names are in
the internal format (e.g., "blk.0.attn_q.weight").

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

L<Lugh>, L<Lugh::Inference>, L<Lugh::KVCache>

=head1 AUTHOR

Your Name Here

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
