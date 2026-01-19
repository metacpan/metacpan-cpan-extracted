package Lugh::Context;

use strict;
use warnings;

=head1 NAME

Lugh::Context - Memory Context for Tensor Allocation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Lugh;
    
    # Create a context with 16 MB of memory
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Create tensors in this context
    my $a = Lugh::Tensor->new_f32($ctx, 1024);
    my $b = Lugh::Tensor->new_f32($ctx, 1024);
    
    # Tensors are automatically freed when context goes out of scope

=head1 DESCRIPTION

Lugh::Context provides memory management for tensor allocation. It wraps
ggml's context system, which uses a memory arena for efficient allocation
of many tensors without individual malloc/free overhead.

=head2 Memory Arena

When you create a Context, a contiguous block of memory is allocated.
All tensors created in that context share this memory arena:

    Context (16 MB arena)
    ┌─────────────────────────────────────────────────┐
    │ Tensor A (4KB) │ Tensor B (16KB) │ Tensor C ... │
    └─────────────────────────────────────────────────┘

Benefits:

=over 4

=item * B<Fast allocation> - No system malloc per tensor

=item * B<Cache friendly> - Tensors are contiguous in memory

=item * B<Simple cleanup> - Free entire context at once

=back

=head2 Context Types

There are several common patterns for context usage:

=over 4

=item * B<Weight context> - Long-lived, holds model weights (read from GGUF)

=item * B<Compute context> - Short-lived, holds computation graph tensors

=item * B<Scratch context> - Temporary, holds intermediate values

=back

For high-level inference, you typically don't need to manage contexts
directly - Lugh::Model and Lugh::Inference handle this internally.

=head1 CONSTRUCTOR

=head2 new

    my $ctx = Lugh::Context->new(
        mem_size => $bytes
    );

Creates a new memory context.

B<Parameters:>

=over 4

=item * C<mem_size> (required) - Size of memory arena in bytes

=back

B<Returns:> A Lugh::Context object.

B<Throws:> Dies if memory allocation fails or if maximum contexts exceeded.

B<Memory Sizing:>

The memory size should account for:

=over 4

=item * Tensor metadata (about 256 bytes per tensor)

=item * Tensor data (depends on type and dimensions)

=item * Alignment padding

=back

Rule of thumb: allocate 2-3× the expected tensor data size.

B<Example:>

    # Small context for a few tensors
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);  # 1 MB
    
    # Large context for model weights
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024 * 1024);  # 1 GB

=head1 METHODS

=head2 mem_size

    my $bytes = $ctx->mem_size;

Returns the total size of the memory arena.

=head2 mem_used

    my $bytes = $ctx->mem_used;

Returns the amount of memory currently used by tensors.

B<Example:>

    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    print "Used: ", $ctx->mem_used, " bytes\n";  # Initially small
    
    my $tensor = Lugh::Tensor->new_f32($ctx, 1000);
    print "Used: ", $ctx->mem_used, " bytes\n";  # +4000 bytes for data

=head1 MEMORY MANAGEMENT

=head2 Automatic Cleanup

When a Context object goes out of scope, its destructor automatically
frees the entire memory arena:

    {
        my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
        my $tensor = Lugh::Tensor->new_f32($ctx, 1000);
        # ... use tensor ...
    }
    # $ctx is freed here, including all tensors

B<Warning:> Never use a tensor after its context has been freed!

=head2 Maximum Contexts

There is a compile-time limit on the number of simultaneous contexts
(default: 4096). This is rarely an issue in practice.

=head2 No Individual Tensor Free

You cannot free individual tensors within a context. This is by design -
the arena allocator trades flexibility for speed. If you need to free
tensors individually, use separate contexts.

=head1 TENSOR CREATION

Tensors are created using the static methods on Lugh::Tensor, passing
the context as the first argument:

    my $f32_1d = Lugh::Tensor->new_f32($ctx, 100);
    my $f32_2d = Lugh::Tensor->new_f32($ctx, 100, 200);
    my $f32_3d = Lugh::Tensor->new_f32($ctx, 100, 200, 300);
    my $f32_4d = Lugh::Tensor->new_f32($ctx, 100, 200, 300, 400);

Memory usage for F32 tensors:

    Dimensions      Elements     Memory
    (100)          100          400 bytes
    (100, 200)     20,000       80 KB
    (100, 200, 300) 6,000,000   24 MB

=head1 LOW-LEVEL OPERATIONS

For advanced users, contexts can be used with the low-level Lugh::Ops
and Lugh::Graph modules:

    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    my $a = Lugh::Tensor->new_f32($ctx, 1000);
    my $b = Lugh::Tensor->new_f32($ctx, 1000);
    
    $a->set_f32(1.0, 2.0, 3.0, ...);
    $b->set_f32(4.0, 5.0, 6.0, ...);
    
    my $c = Lugh::Ops::add($ctx, $a, $b);
    
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($c);
    $graph->compute($ctx, 4);  # 4 threads
    
    my @result = $c->get_f32();

=head1 THREAD SAFETY

Lugh::Context objects are NOT thread-safe. The internal registry uses
mutex locks, but individual contexts should not be shared across Perl
threads. Each thread must create its own contexts.

For multi-threaded computation, use C<< $graph->compute($ctx, $n_threads) >>
which parallelizes within a single Perl thread using pthreads.

=head1 IMPLEMENTATION NOTES

=head2 Registry Pattern

Contexts are tracked in a global registry using integer IDs. This allows
safe Perl object destruction and thread cloning:

    Perl SV → Magic → ID → Registry → LughContext → ggml_context

=head2 ggml Context

Internally, this wraps C<struct ggml_context*> from the ggml library.
The ggml context provides:

=over 4

=item * Memory arena management

=item * Tensor allocation

=item * Computation graph building

=item * Thread-safe graph execution

=back

=head1 SEE ALSO

L<Lugh>, L<Lugh::Tensor>, L<Lugh::Graph>, L<Lugh::Ops>

L<https://github.com/ggerganov/ggml> - ggml library

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
