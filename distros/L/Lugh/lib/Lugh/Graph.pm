package Lugh::Graph;

use strict;
use warnings;
use Lugh;

=head1 NAME

Lugh::Graph - Computation Graph for Tensor Operations

=encoding utf8

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Lugh;
    
    # Create context and tensors
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    my $a = Lugh::Tensor->new_f32($ctx, 1000);
    my $b = Lugh::Tensor->new_f32($ctx, 1000);
    $a->set_f32(@a_data);
    $b->set_f32(@b_data);
    
    # Build computation
    my $c = Lugh::Ops::add($ctx, $a, $b);
    my $d = Lugh::Ops::mul($ctx, $c, $c);
    my $e = Lugh::Ops::soft_max($ctx, $d);
    
    # Create graph and add operations
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($e);
    
    # Execute computation
    $graph->compute($ctx, 4);  # Use 4 threads
    
    # Read results
    my @result = $e->get_f32();

=head1 DESCRIPTION

Lugh::Graph represents a computation graph - a directed acyclic graph (DAG)
of tensor operations. The graph enables:

=over 4

=item * B<Lazy evaluation> - Operations are not computed until graph is run

=item * B<Optimization> - ggml can fuse and optimize operations

=item * B<Parallelization> - Multiple threads for matrix operations

=item * B<Memory planning> - Efficient allocation of intermediate tensors

=back

=head2 Graph Structure

A computation graph consists of nodes (tensors) and edges (dependencies):

    Input A    Input B
       │          │
       └────┬─────┘
            │
         Add(A,B) = C
            │
            ├─────────┐
            │         │
         Mul(C,C) = D │
            │         │
            └────┬────┘
                 │
            SoftMax(D) = E
                 │
              Output

The graph tracks dependencies so operations execute in correct order.

=head2 Build Phase vs Compute Phase

=over 4

=item 1. B<Build Phase> - Create tensors and operations, recording the graph

=item 2. B<Compute Phase> - Execute all operations in dependency order

=back

This separation allows the same graph to be executed multiple times
with different input values.

=head1 CONSTRUCTOR

=head2 new

    my $graph = Lugh::Graph->new($context);

Creates a new empty computation graph.

B<Parameters:>

=over 4

=item * C<$context> - A Lugh::Context object for graph metadata

=back

B<Returns:> A Lugh::Graph object.

B<Example:>

    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    my $graph = Lugh::Graph->new($ctx);

=head1 METHODS

=head2 build_forward

    $graph->build_forward($output_tensor);

Adds an output tensor and all its dependencies to the graph.

B<Parameters:>

=over 4

=item * C<$output_tensor> - The tensor to compute (a Lugh::Tensor)

=back

B<Details:>

This method traverses backwards from the output tensor, adding all
required operations to the graph. Multiple outputs can be added by
calling build_forward multiple times.

B<Example:>

    my $loss = Lugh::Ops::...;
    my $accuracy = Lugh::Ops::...;
    
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($loss);
    $graph->build_forward($accuracy);

=head2 compute

    $graph->compute($context, $n_threads);

Executes all operations in the graph.

B<Parameters:>

=over 4

=item * C<$context> - The context for computation

=item * C<$n_threads> - Number of CPU threads to use

=back

B<Thread Usage:>

=over 4

=item * B<1 thread> - Sequential execution, lowest overhead

=item * B<N threads> - Parallel matrix operations (recommended: CPU cores)

=item * B<Too many threads> - Diminishing returns, overhead increases

=back

B<Example:>

    # Single-threaded
    $graph->compute($ctx, 1);
    
    # Use all CPU cores (example for 8-core machine)
    $graph->compute($ctx, 8);
    
    # Common recommendation
    use Sys::Info;
    my $info = Sys::Info->new;
    my $cpu = $info->device('CPU');
    $graph->compute($ctx, $cpu->count);

=head1 GRAPH OPERATIONS

=head2 Multiple Outputs

    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($output1);
    $graph->build_forward($output2);
    $graph->compute($ctx, 4);
    
    # Both outputs are now computed
    my @result1 = $output1->get_f32();
    my @result2 = $output2->get_f32();

=head2 Reusing a Graph

    # Build once
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($output);
    
    # Run multiple times with different inputs
    for my $input_data (@all_inputs) {
        $input->set_f32(@$input_data);
        $graph->compute($ctx, 4);
        my @result = $output->get_f32();
        push @all_results, \@result;
    }

=head1 EXECUTION MODEL

=head2 Forward Execution

Operations are executed in topological order (dependencies first):

    1. Input tensors (already have data)
    2. First layer of operations
    3. Second layer of operations
    4. ... and so on to outputs

=head2 Memory Allocation

ggml allocates memory for intermediate tensors during computation.
The context must have enough memory for:

=over 4

=item * Input tensors

=item * Output tensors

=item * All intermediate tensors

=item * Graph metadata

=back

=head2 Thread Pool

When using multiple threads, ggml creates a thread pool:

    Main Thread
         │
    ┌────┴────┬────────┬────────┐
    │         │        │        │
    Worker 0  Worker 1  Worker 2  Worker 3
    │         │        │        │
    └────┬────┴────────┴────────┘
         │
    Barrier Sync
         │
    Next Operation

Matrix multiplications and other large operations are parallelized
across workers.

=head1 PERFORMANCE TIPS

=head2 Batch Operations

Instead of many small graph executions, batch inputs:

    # Slower: Many small graphs
    for my $input (@inputs) {
        $graph->compute($ctx, 4);
    }
    
    # Faster: One large computation
    # (if using batched tensors)
    $batched_graph->compute($ctx, 4);

=head2 Memory Reuse

The same context can be reused for multiple graph executions,
avoiding repeated memory allocation.

=head2 Graph Caching

For inference, build the graph once and reuse:

    # Build once at startup
    my $inference_graph = build_inference_graph($model);
    
    # Reuse for each query
    sub infer {
        my ($tokens) = @_;
        $input_tensor->set_data(@$tokens);
        $inference_graph->compute($ctx, 4);
        return $output_tensor->get_f32();
    }

=head1 BACKEND SELECTION

ggml automatically selects the best compute backend:

=over 4

=item * B<CPU> - Always available, uses SIMD (SSE/AVX/NEON)

=item * B<Metal> - Apple Silicon and AMD GPUs on macOS

=item * B<CUDA> - NVIDIA GPUs

=item * B<Vulkan> - Cross-platform GPU

=item * B<BLAS> - Accelerate (macOS) or OpenBLAS for matrix ops

=back

The backend is selected at ggml build time and runtime.

=head1 DEBUGGING

=head2 Graph Size

    # After building
    my $n_nodes = ...;  # (Not yet exposed, could add)
    print "Graph has $n_nodes operations\n";

=head2 Operation Timing

For performance analysis, you can time the compute call:

    use Time::HiRes qw(time);
    
    my $start = time();
    $graph->compute($ctx, 4);
    my $elapsed = time() - $start;
    
    print "Compute took ${elapsed}s\n";

=head1 ERROR HANDLING

=head2 Common Errors

=over 4

=item * B<Shape mismatch> - Operations require compatible tensor shapes

=item * B<Out of memory> - Context too small for tensors

=item * B<Null tensor> - Operation returned NULL (allocation failure)

=back

=head2 Error Recovery

Graph operations die on error. Use eval for error handling:

    eval {
        $graph->compute($ctx, 4);
    };
    if ($@) {
        warn "Computation failed: $@";
        # Handle error...
    }

=head1 THREAD SAFETY

Graph objects are NOT thread-safe. Each Perl thread should create
its own graphs. However, the compute() method uses internal threading
that is safe.

=head1 IMPLEMENTATION NOTES

Internally, Lugh::Graph wraps C<struct ggml_cgraph*>:

    struct ggml_cgraph {
        int n_nodes;
        int n_leafs;
        struct ggml_tensor ** nodes;  // Operations
        struct ggml_tensor ** grads;  // Gradients (for training)
        struct ggml_tensor ** leafs;  // Inputs
        ...
    };

The graph is computed using C<ggml_graph_compute_with_ctx()>.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Context>, L<Lugh::Tensor>, L<Lugh::Ops>

L<https://github.com/ggerganov/ggml> - ggml library

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
