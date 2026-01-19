package Lugh::Ops;

use strict;
use warnings;

=head1 NAME

Lugh::Ops - Tensor Operations for Neural Network Computation

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Lugh;
    
    my $ctx = Lugh::Context->new(mem_size => 10 * 1024 * 1024);
    
    # Create input tensors
    my $a = Lugh::Tensor->new_f32($ctx, 100);
    my $b = Lugh::Tensor->new_f32($ctx, 100);
    $a->set_f32(@a_data);
    $b->set_f32(@b_data);
    
    # Arithmetic operations
    my $sum = Lugh::Ops::add($ctx, $a, $b);
    my $product = Lugh::Ops::mul($ctx, $a, $b);
    
    # Matrix operations
    my $w = Lugh::Tensor->new_f32($ctx, 100, 50);
    my $x = Lugh::Tensor->new_f32($ctx, 100, 10);
    my $y = Lugh::Ops::mul_mat($ctx, $w, $x);
    
    # Activation functions
    my $activated = Lugh::Ops::silu($ctx, $a);
    my $probs = Lugh::Ops::soft_max($ctx, $a);
    
    # Normalization
    my $normed = Lugh::Ops::rms_norm($ctx, $a, 1e-5);
    
    # Build and compute
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($sum);
    $graph->compute($ctx, 4);
    
    my @result = $sum->get_f32();

=head1 DESCRIPTION

Lugh::Ops provides tensor operations that form the building blocks of
neural network computation. These operations create computation graph
nodes that are evaluated lazily when the graph is computed.

All operations are static functions that take a context and input
tensor(s), returning a new tensor representing the operation result.

=head2 Lazy Evaluation

Operations don't compute results immediately. Instead, they build a
computation graph:

    my $a = Lugh::Tensor->new_f32($ctx, 100);
    my $b = Lugh::Tensor->new_f32($ctx, 100);
    my $c = Lugh::Ops::add($ctx, $a, $b);  # No computation yet!
    
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($c);
    $graph->compute($ctx, 4);  # Computation happens here
    
    my @result = $c->get_f32();  # Now we can read results

This allows ggml to optimize the computation and use multiple threads.

=head1 FUNCTIONS

=head2 add

    my $c = Lugh::Ops::add($ctx, $a, $b);

Element-wise addition of two tensors.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$a> - First tensor

=item * C<$b> - Second tensor (must match shape or be broadcastable)

=back

B<Returns:> A new tensor C = A + B.

B<Example:>

    my $a = ...;  # [1.0, 2.0, 3.0]
    my $b = ...;  # [4.0, 5.0, 6.0]
    my $c = Lugh::Ops::add($ctx, $a, $b);
    # Result: [5.0, 7.0, 9.0]

=head2 mul

    my $c = Lugh::Ops::mul($ctx, $a, $b);

Element-wise multiplication of two tensors.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$a> - First tensor

=item * C<$b> - Second tensor (must match shape or be broadcastable)

=back

B<Returns:> A new tensor C = A * B (element-wise).

B<Example:>

    my $a = ...;  # [1.0, 2.0, 3.0]
    my $b = ...;  # [4.0, 5.0, 6.0]
    my $c = Lugh::Ops::mul($ctx, $a, $b);
    # Result: [4.0, 10.0, 18.0]

=head2 mul_mat

    my $c = Lugh::Ops::mul_mat($ctx, $a, $b);

Matrix multiplication.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$a> - Left matrix [K, N]

=item * C<$b> - Right matrix [K, M]

=back

B<Returns:> A new tensor C = A^T × B with shape [N, M].

B<Note:> ggml's mul_mat has specific dimension semantics. For standard
matrix multiply A × B where A is [M, K] and B is [K, N]:

    # Transpose A and pass to mul_mat
    C = mul_mat(A^T, B)  # C is [M, N]

In practice for neural networks:

    # Weight matrix W: [out_dim, in_dim]
    # Input X: [in_dim, batch]
    # Output: [out_dim, batch]
    my $output = Lugh::Ops::mul_mat($ctx, $weights, $input);

B<Example:>

    my $w = Lugh::Tensor->new_f32($ctx, 100, 50);   # [100, 50]
    my $x = Lugh::Tensor->new_f32($ctx, 100, 10);   # [100, 10]
    my $y = Lugh::Ops::mul_mat($ctx, $w, $x);       # [50, 10]

=head2 soft_max

    my $probs = Lugh::Ops::soft_max($ctx, $logits);

Applies softmax to convert logits to probabilities.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$logits> - Input tensor

=back

B<Returns:> A new tensor with softmax applied along the first dimension.

B<Formula:>

    softmax(x_i) = exp(x_i) / Σ exp(x_j)

The output sums to 1.0 along the softmax dimension.

B<Example:>

    my $logits = ...;  # [2.0, 1.0, 0.1]
    my $probs = Lugh::Ops::soft_max($ctx, $logits);
    # Result: [0.659, 0.242, 0.099]  (sums to 1.0)

=head2 rms_norm

    my $normed = Lugh::Ops::rms_norm($ctx, $x, $eps);

Applies Root Mean Square Layer Normalization.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$x> - Input tensor

=item * C<$eps> - Epsilon for numerical stability (e.g., 1e-5)

=back

B<Returns:> A new tensor with RMSNorm applied.

B<Formula:>

    RMSNorm(x) = x / √(mean(x²) + ε)

Unlike LayerNorm, RMSNorm does not center the values (no mean subtraction).

B<Example:>

    my $x = ...;
    my $normed = Lugh::Ops::rms_norm($ctx, $x, 1e-5);
    # RMS of $normed is approximately 1.0

=head2 silu

    my $activated = Lugh::Ops::silu($ctx, $x);

Applies the SiLU (Sigmoid Linear Unit) activation function.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context object

=item * C<$x> - Input tensor

=back

B<Returns:> A new tensor with SiLU applied element-wise.

B<Formula:>

    SiLU(x) = x × σ(x) = x / (1 + exp(-x))

Also known as "Swish" activation. Used in modern LLMs like LLaMA.

B<Example:>

    my $x = ...;  # [-1.0, 0.0, 1.0]
    my $y = Lugh::Ops::silu($ctx, $x);
    # Result: [-0.269, 0.0, 0.731]

=head1 ADDITIONAL OPERATIONS

The XS code exposes these operations. Additional ggml operations can
be added as needed:

=head2 Unary Operations

=over 4

=item * C<neg> - Negate: -x

=item * C<abs> - Absolute value: |x|

=item * C<sqr> - Square: x²

=item * C<sqrt> - Square root: √x

=item * C<exp> - Exponential: e^x

=item * C<log> - Natural logarithm: ln(x)

=item * C<sin>, C<cos> - Trigonometric functions

=item * C<relu> - ReLU: max(0, x)

=item * C<gelu> - GELU activation

=item * C<tanh> - Hyperbolic tangent

=back

=head2 Binary Operations

=over 4

=item * C<sub> - Subtraction: a - b

=item * C<div> - Division: a / b

=item * C<scale> - Scale: a × scalar

=back

=head2 Reduction Operations

=over 4

=item * C<sum> - Sum of elements

=item * C<mean> - Mean of elements

=item * C<max> - Maximum element

=item * C<min> - Minimum element

=back

=head2 Shape Operations

=over 4

=item * C<reshape> - Change tensor shape

=item * C<permute> - Transpose dimensions

=item * C<transpose> - Swap two dimensions

=item * C<view> - Create a view with different strides

=item * C<cont> - Make tensor contiguous in memory

=back

=head2 Attention Operations

=over 4

=item * C<diag_mask_inf> - Apply causal mask (upper triangle → -inf)

=item * C<rope_ext> - Apply rotary position embeddings

=item * C<flash_attn_ext> - Flash attention (optimized)

=back

=head1 BROADCASTING

Operations support NumPy-style broadcasting:

    # Scalar × Vector
    my $scalar = Lugh::Tensor->new_f32($ctx, 1);
    my $vector = Lugh::Tensor->new_f32($ctx, 100);
    my $result = Lugh::Ops::mul($ctx, $scalar, $vector);  # [100]
    
    # Row × Matrix
    my $row = Lugh::Tensor->new_f32($ctx, 100, 1);     # [100, 1]
    my $matrix = Lugh::Tensor->new_f32($ctx, 100, 50); # [100, 50]
    my $result = Lugh::Ops::mul($ctx, $row, $matrix);  # [100, 50]

Broadcasting rules:

=over 4

=item 1. Dimensions are compared from right to left

=item 2. Dimensions match if equal or one of them is 1

=item 3. Missing dimensions are treated as 1

=back

=head1 OPERATION FUSION

ggml automatically fuses compatible operations when building the
computation graph, reducing memory traffic and improving performance:

    # These may be fused into a single kernel:
    my $x = Lugh::Ops::mul($ctx, $a, $b);
    my $y = Lugh::Ops::add($ctx, $x, $c);

=head1 GPU ACCELERATION

On supported platforms, operations automatically use:

=over 4

=item * B<Metal> - Apple GPU acceleration on macOS

=item * B<CUDA> - NVIDIA GPU acceleration

=item * B<Vulkan> - Cross-platform GPU

=item * B<BLAS> - Accelerate/OpenBLAS for matrix operations

=back

No code changes needed - ggml selects the best backend.

=head1 THREAD SAFETY

Operation functions are thread-safe - they only create graph nodes.
The actual computation happens in C<< $graph->compute() >> which
handles parallelization internally.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Context>, L<Lugh::Tensor>, L<Lugh::Graph>

L<https://github.com/ggerganov/ggml> - ggml library

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
