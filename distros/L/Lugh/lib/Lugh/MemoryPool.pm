package Lugh::MemoryPool;

use strict;
use warnings;

our $VERSION = '0.12';

# XS methods are loaded via Lugh.xs
# This module provides documentation only

1;

__END__

=head1 NAME

Lugh::MemoryPool - Reusable compute resources for efficient inference

=head1 SYNOPSIS

    use Lugh;

    # Load model and create inference engine
    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);

    # Create a memory pool for reusable resources
    my $pool = $inference->create_memory_pool();

    # Use the pool for multiple inference calls
    my @tokens = $tokenizer->encode("Hello, world!");

    my @logits = $inference->forward_pool(
        tokens => \@tokens,
        pool   => $pool,
    );

    # Reset the pool for the next request
    $pool->reset();

    # Use again with different input
    my @tokens2 = $tokenizer->encode("How are you?");
    my @logits2 = $inference->forward_pool(
        tokens => \@tokens2,
        pool   => $pool,
    );

=head1 DESCRIPTION

C<Lugh::MemoryPool> provides pre-allocated compute resources that can be
reused across multiple inference calls. This eliminates the overhead of
allocating and freeing memory for each forward pass, significantly
improving throughput for applications that process many requests.

Memory pools are created from a C<Lugh::Inference> object using the
C<create_memory_pool()> method. Each pool contains:

=over 4

=item * A compute context for building graphs

=item * A backend instance for execution

=item * A graph allocator for tensor memory

=back

=head1 METHODS

=head2 reset

    $pool->reset();

Resets the memory pool to its initial state, ready for the next inference
call. This must be called between inference requests to clear the previous
computation graph.

B<Returns:> True (1) on success, false (0) on failure.

B<Example:>

    # Process multiple requests efficiently
    for my $text (@requests) {
        my @tokens = $tokenizer->encode($text);
        my @logits = $inference->forward_pool(
            tokens => \@tokens,
            pool   => $pool,
        );

        # Process logits...

        $pool->reset();  # Prepare for next request
    }

=head2 DESTROY

Called automatically when the pool goes out of scope. Frees all allocated
resources including the backend, allocator, and compute context.

=head1 CREATING A MEMORY POOL

Memory pools are created via C<Lugh::Inference>:

    my $pool = $inference->create_memory_pool();

The pool inherits configuration from the inference object, including:

=over 4

=item * Backend selection (Metal, CPU, etc.)

=item * Thread count

=item * Memory allocation size

=back

=head1 USING WITH FORWARD METHODS

Use C<forward_pool()> or C<forward_cache_pool()> to leverage the pool:

    # Without KV cache
    my @logits = $inference->forward_pool(
        tokens => \@tokens,
        pool   => $pool,
    );

    # With KV cache
    my $cache = $inference->create_kv_cache();
    my @logits = $inference->forward_cache_pool(
        tokens => \@tokens,
        cache  => $cache,
        pool   => $pool,
    );

=head1 PERFORMANCE CONSIDERATIONS

=head2 When to Use Memory Pools

Memory pools provide the most benefit when:

=over 4

=item * Processing many short requests (chatbots, APIs)

=item * Low latency is critical

=item * Memory allocation overhead is noticeable in profiling

=back

=head2 When Not to Use Memory Pools

Pools may not be necessary when:

=over 4

=item * Processing few, long sequences

=item * Memory is severely constrained

=item * Using batch processing (which has its own optimizations)

=back

=head2 Memory Usage

Each pool allocates a fixed amount of memory (typically 512MB for the
compute context). This memory is reused but not freed until the pool
is destroyed.

=head1 THREAD SAFETY

Memory pools are B<not thread-safe>. Each thread should have its own pool.
The pool can be safely reused sequentially within a single thread.

=head1 EXAMPLE: HIGH-THROUGHPUT INFERENCE

    use Lugh;

    my $model = Lugh::Model->new(model => 'model.gguf');
    my $tokenizer = Lugh::Tokenizer->new(model => $model);
    my $inference = Lugh::Inference->new(model => $model);

    # Pre-allocate resources
    my $pool = $inference->create_memory_pool();
    my $cache = $inference->create_kv_cache();

    # Process requests efficiently
    sub generate_response {
        my ($prompt) = @_;

        # Reset resources
        $pool->reset();
        $cache->clear();

        my @tokens = $tokenizer->encode($prompt);
        my @generated;

        for (1..100) {  # Generate up to 100 tokens
            my @logits = $inference->forward_cache_pool(
                tokens => \@tokens,
                cache  => $cache,
                pool   => $pool,
            );

            my $next = $inference->sample_top_p(\@logits, temperature => 0.8);
            last if $next == $tokenizer->eos_id;

            push @generated, $next;
            push @tokens, $next;

            $pool->reset();  # Reset for next iteration
        }

        return $tokenizer->decode(\@generated);
    }

=head1 SEE ALSO

L<Lugh::Inference> - Main inference class with C<create_memory_pool()>

L<Lugh::KVCache> - Key-value cache for efficient generation

L<Lugh> - Main module documentation

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
