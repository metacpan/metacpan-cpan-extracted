package Lugh::KVCache;

use strict;
use warnings;
use Lugh;

our $VERSION = '0.12';

=head1 NAME

Lugh::KVCache - KV Cache for efficient incremental decoding

=encoding utf8

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Model;
    use Lugh::Inference;
    
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $inference = Lugh::Inference->new(model => $model);
    
    # Create cache from inference engine (recommended)
    my $cache = $inference->create_kv_cache();
    
    # Or create directly with explicit parameters
    my $cache = Lugh::KVCache->new(
        n_layer   => 22,
        n_ctx     => 2048,
        n_head_kv => 4,
        head_dim  => 64,
    );
    
    # Prefill: process prompt tokens
    my @prompt_tokens = (1, 450, 4996, 310);
    my @logits = $inference->forward_cache($cache, \@prompt_tokens);
    
    # Decode: generate one token at a time efficiently
    my $next_token = argmax(\@logits);
    @logits = $inference->forward_cache($cache, [$next_token]);
    
    # Check cache state
    print "Cached tokens: ", $cache->n_cached, "\n";
    print "Max context: ", $cache->n_ctx, "\n";
    
    # Clear cache for new sequence
    $cache->clear();

=head1 DESCRIPTION

Lugh::KVCache stores Key and Value tensors from previous tokens to avoid
recomputation during autoregressive generation. This provides significant
speedup for incremental decoding where each new token only requires
computing attention over one new position while reusing cached K/V from
previous positions.

=head2 How KV Caching Works

During transformer inference, each layer computes Query (Q), Key (K), and
Value (V) projections. In standard attention:

    Attention(Q, K, V) = softmax(QK^T / sqrt(d)) * V

For autoregressive generation, previous tokens' K and V values don't change.
The KV cache stores these values so they don't need to be recomputed:

=over 4

=item 1. B<Prefill Phase>: Process all prompt tokens, store K/V in cache

=item 2. B<Decode Phase>: For each new token, compute only its Q/K/V,
concatenate K/V with cache, compute attention, update cache

=back

This reduces complexity from O(n²) to O(n) per generated token.

=head2 Thread Safety

Each KV cache instance has its own mutex for thread-safe access. Multiple
threads can safely use different cache instances. The cache is locked
during forward passes and state modifications.

=head1 METHODS

=head2 new

    my $cache = Lugh::KVCache->new(
        n_layer   => 22,      # Number of transformer layers
        n_ctx     => 2048,    # Maximum context length
        n_head_kv => 4,       # Number of KV heads (for GQA)
        head_dim  => 64,      # Dimension per head
    );

Creates a new KV cache. All parameters are required when creating directly.
Use C<< $inference->create_kv_cache() >> for automatic configuration from
the loaded model.

=head2 n_cached

    my $count = $cache->n_cached();

Returns the number of tokens currently cached.

=head2 n_ctx

    my $max = $cache->n_ctx();

Returns the maximum context length (cache capacity).

=head2 n_layer

    my $layers = $cache->n_layer();

Returns the number of transformer layers in the cache.

=head2 clear

    $cache->clear();

Clears all cached K/V values and resets n_cached to 0.

=head2 resize

    $cache->resize($new_n_cached);

Truncates the cache to the specified number of tokens. Useful for
implementing context window sliding or rollback.

=head1 USAGE WITH INFERENCE

The recommended way to use KV caching:

    # Setup
    my $model = Lugh::Model->new(model => $model_path);
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);
    my $cache = $inference->create_kv_cache();
    
    # Encode prompt
    my @tokens = $tokenizer->encode("Once upon a time");
    
    # Prefill
    my @logits = $inference->forward_cache($cache, \@tokens);
    
    # Generate tokens
    for (1..100) {
        my $next = sample_top_p(\@logits, 0.9);
        last if $next == $tokenizer->eos_token;
        
        push @tokens, $next;
        @logits = $inference->forward_cache($cache, [$next]);
    }
    
    print $tokenizer->decode(\@tokens);

=head2 Using with LoRA

KV caching works with LoRA adapters using named parameters:

    use Lugh::LoRA;
    
    my $lora = Lugh::LoRA->new(
        adapter => 'adapter.gguf',
        model   => $model,
    );
    my $cache = $inference->create_kv_cache();
    
    # Prefill with LoRA
    my @logits = $inference->forward_cache(
        cache  => $cache,
        tokens => \@tokens,
        lora   => $lora,
    );
    
    # Incremental decoding with LoRA
    for (1..100) {
        my $next = sample_top_p(\@logits, 0.9);
        last if $next == $tokenizer->eos_token;
        
        @logits = $inference->forward_cache(
            cache  => $cache,
            tokens => [$next],
            lora   => $lora,
        );
    }

=head1 SEE ALSO

L<Lugh>, L<Lugh::Inference>, L<Lugh::Model>, L<Lugh::LoRA>

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
