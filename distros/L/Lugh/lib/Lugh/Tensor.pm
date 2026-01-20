package Lugh::Tensor;

use strict;
use warnings;
use Lugh;

=head1 NAME

Lugh::Tensor - N-Dimensional Tensor with ggml Backend

=encoding utf8

=head1 VERSION

Version 0.08

=cut

our $VERSION = '0.08';

=head1 SYNOPSIS

    use Lugh;
    
    # Create a context
    my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
    
    # Create tensors
    my $vector = Lugh::Tensor->new_f32($ctx, 100);           # 1D
    my $matrix = Lugh::Tensor->new_f32($ctx, 100, 200);      # 2D
    my $tensor3d = Lugh::Tensor->new_f32($ctx, 10, 20, 30);  # 3D
    
    # Set values
    $vector->set_f32(1.0, 2.0, 3.0, ...);  # Must provide all elements
    
    # Get values
    my @values = $vector->get_f32();
    
    # Get tensor properties
    my $n = $tensor->nelements();  # Total element count
    my $dims = $tensor->n_dims();  # Number of dimensions
    my @shape = $tensor->shape();  # Size of each dimension

=head1 DESCRIPTION

Lugh::Tensor represents an N-dimensional array of numbers, implemented
using ggml's tensor system. Tensors are the fundamental building blocks
for neural network computations.

=head2 Tensor Properties

=over 4

=item * B<Data type> - F32 (32-bit float), or quantized types for model weights

=item * B<Dimensions> - 1D to 4D arrays

=item * B<Shape> - Size of each dimension

=item * B<Strides> - Memory layout for traversal

=back

=head2 Memory Layout

Tensors use row-major (C-style) memory layout:

    2D tensor [3, 4]:
    
    Memory: [a00, a01, a02, a03, a10, a11, a12, a13, a20, a21, a22, a23]
    
    Logical:
        a00 a01 a02 a03
        a10 a11 a12 a13
        a20 a21 a22 a23

The first dimension changes fastest in memory.

=head1 CONSTRUCTOR

=head2 new_f32

    my $tensor = Lugh::Tensor->new_f32($context, @dimensions);

Creates a new tensor with F32 (32-bit float) data type.

B<Parameters:>

=over 4

=item * C<$context> - A Lugh::Context object

=item * C<@dimensions> - 1 to 4 dimension sizes

=back

B<Returns:> A Lugh::Tensor object.

B<Throws:> Dies if allocation fails or dimensions are invalid.

B<Examples:>

    # 1D vector with 100 elements
    my $v = Lugh::Tensor->new_f32($ctx, 100);
    
    # 2D matrix with 100 rows, 200 columns
    my $m = Lugh::Tensor->new_f32($ctx, 100, 200);
    
    # 3D tensor
    my $t = Lugh::Tensor->new_f32($ctx, 10, 20, 30);
    
    # 4D tensor (max dimensions)
    my $t4 = Lugh::Tensor->new_f32($ctx, 2, 3, 4, 5);

=head1 METHODS

=head2 set_f32

    $tensor->set_f32(@values);

Sets all tensor elements from a list of values.

B<Parameters:>

=over 4

=item * C<@values> - Exactly nelements() float values

=back

B<Throws:> Dies if wrong number of values provided.

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 3);
    $t->set_f32(1.0, 2.0, 3.0);

=head2 get_f32

    my @values = $tensor->get_f32();

Returns all tensor elements as a list.

B<Returns:> A list of nelements() float values.

B<Example:>

    my @data = $tensor->get_f32();
    print "First element: $data[0]\n";
    print "Sum: ", sum(@data), "\n";

=head2 nelements

    my $n = $tensor->nelements();

Returns the total number of elements in the tensor.

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 10, 20, 30);
    print $t->nelements();  # 6000

=head2 n_dims

    my $dims = $tensor->n_dims();

Returns the number of dimensions (1-4).

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 10, 20);
    print $t->n_dims();  # 2

=head2 shape

    my @shape = $tensor->shape();

Returns the size of each dimension.

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 10, 20, 30);
    my @shape = $t->shape();  # (10, 20, 30)

=head2 type

    my $type_id = $tensor->type();

Returns the numeric type ID of the tensor (e.g., 0 for F32, 12 for Q4_K).

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 100);
    print $t->type();  # 0 (F32)

=head2 type_name

    my $name = $tensor->type_name();

Returns the string name of the tensor's type.

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 100);
    print $t->type_name();  # "f32"
    
    # From a quantized model tensor
    print $weight_tensor->type_name();  # "q4_K"

=head2 type_size

    my $bytes = $tensor->type_size();

Returns the size in bytes of one block of this type.

=head2 blck_size

    my $elements = $tensor->blck_size();

Returns the number of elements per block. For quantized types this is
typically 32 or 256.

=head2 is_quantized

    my $bool = $tensor->is_quantized();

Returns true if the tensor uses a quantized data type.

B<Example:>

    if ($tensor->is_quantized()) {
        print "Tensor uses ", $tensor->type_name(), " quantization\n";
    }

=head2 nbytes

    my $bytes = $tensor->nbytes();

Returns the total number of bytes used by the tensor's data.

B<Example:>

    my $t = Lugh::Tensor->new_f32($ctx, 1000);
    print $t->nbytes();  # 4000 (1000 × 4 bytes)

=head2 quantize

    my $quantized = $tensor->quantize($ctx, $dest_type);

Quantizes an F32 tensor to the specified quantized type. Returns a new tensor.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context with enough memory for the result

=item * C<$dest_type> - Target quantization type (from Lugh::Quant)

=back

B<Returns:> A new Lugh::Tensor with the quantized data.

B<Throws:> Dies if source is not F32 or destination is not a quantized type.

B<Example:>

    use Lugh::Quant qw(Q4_K);
    
    my $f32 = Lugh::Tensor->new_f32($ctx, 256);
    $f32->set_f32(@weights);
    
    my $q4 = $f32->quantize($ctx, Q4_K);
    printf "Compressed: %d -> %d bytes\n", $f32->nbytes, $q4->nbytes;

=head2 dequantize

    my $f32 = $tensor->dequantize($ctx);

Dequantizes a quantized (or F16/BF16) tensor back to F32. Returns a new tensor.

B<Parameters:>

=over 4

=item * C<$ctx> - A Lugh::Context with enough memory for the result

=back

B<Returns:> A new F32 Lugh::Tensor.

B<Throws:> Dies if tensor is already F32.

B<Example:>

    # Round-trip: F32 -> Q4_K -> F32
    my $original = Lugh::Tensor->new_f32($ctx, 256);
    $original->set_f32(@data);
    
    my $quantized = $original->quantize($ctx, Lugh::Quant::Q4_K);
    my $restored = $quantized->dequantize($ctx);
    
    # Compare original vs restored to measure quantization loss
    my @orig = $original->get_f32();
    my @rest = $restored->get_f32();

=head1 TENSOR OPERATIONS

Tensors can be used with Lugh::Ops to build computation graphs:

    my $a = Lugh::Tensor->new_f32($ctx, 100);
    my $b = Lugh::Tensor->new_f32($ctx, 100);
    $a->set_f32(@a_data);
    $b->set_f32(@b_data);
    
    # Create operation result tensors
    my $c = Lugh::Ops::add($ctx, $a, $b);      # Element-wise add
    my $d = Lugh::Ops::mul($ctx, $a, $b);      # Element-wise multiply
    my $e = Lugh::Ops::soft_max($ctx, $a);     # Softmax
    
    # Build and compute graph
    my $graph = Lugh::Graph->new($ctx);
    $graph->build_forward($c);
    $graph->compute($ctx, 4);
    
    # Get results
    my @result = $c->get_f32();

=head1 DATA TYPES

ggml supports many tensor data types:

=head2 Float Types

=over 4

=item * B<GGML_TYPE_F32> (0) - 32-bit float (4 bytes per element)

=item * B<GGML_TYPE_F16> (1) - 16-bit float (2 bytes per element)

=item * B<GGML_TYPE_BF16> (30) - Brain float16 (2 bytes per element)

=back

=head2 Quantized Types

Used for model weights to reduce memory:

=over 4

=item * B<Q4_0, Q4_1, Q4_K_S, Q4_K_M> - 4-bit quantization (~0.5 bytes/element)

=item * B<Q5_0, Q5_1, Q5_K_S, Q5_K_M> - 5-bit quantization (~0.625 bytes/element)

=item * B<Q8_0, Q8_1, Q8_K> - 8-bit quantization (1 byte per element)

=item * B<Q2_K, Q3_K> - 2-3 bit quantization (~0.3 bytes/element)

=back

Quantized tensors from model files can be used directly in operations -
ggml handles dequantization automatically during computation.

=head1 BROADCASTING

Many operations support broadcasting (NumPy-style):

    # Scalar broadcast: [1] op [n] -> [n]
    my $scalar = Lugh::Tensor->new_f32($ctx, 1);
    my $vector = Lugh::Tensor->new_f32($ctx, 100);
    my $result = Lugh::Ops::mul($ctx, $scalar, $vector);
    
    # Row broadcast: [1, n] op [m, n] -> [m, n]
    # Column broadcast: [m, 1] op [m, n] -> [m, n]

The broadcasting rules follow standard tensor semantics.

=head1 MATRIX MULTIPLICATION

Matrix multiplication follows the pattern:

    A [k, n] × B [k, m] → C [n, m]
    
    Note: ggml uses column-major interpretation for mul_mat

B<Example:>

    my $a = Lugh::Tensor->new_f32($ctx, 4, 3);  # 3×4 matrix
    my $b = Lugh::Tensor->new_f32($ctx, 4, 2);  # 2×4 matrix
    my $c = Lugh::Ops::mul_mat($ctx, $a, $b);   # 3×2 result

=head1 COMMON TENSOR SHAPES

In transformer models:

=over 4

=item * B<Token embeddings> - [n_embd, n_vocab]

=item * B<Hidden state> - [n_embd, n_tokens]

=item * B<Attention Q/K/V> - [head_dim, n_heads, n_tokens]

=item * B<FFN weights> - [n_embd, ffn_dim] or [ffn_dim, n_embd]

=item * B<Logits> - [n_vocab, n_tokens]

=back

=head1 VIEWS AND RESHAPING

Tensors can be reshaped without copying data:

    # Operations like reshape, permute, transpose
    # create views of the same memory
    
    my $flat = Lugh::Tensor->new_f32($ctx, 120);
    # Internally, ggml can view this as [2,3,4,5] without copying

Note: View operations are internal to ggml. The Perl API currently
focuses on creating new tensors and computing results.

=head1 THREAD SAFETY

Tensor objects themselves are not thread-safe. However, ggml's graph
computation can use multiple CPU threads for parallel operations:

    $graph->compute($ctx, $n_threads);

This uses pthreads internally, parallelizing matrix operations across
the specified number of threads.

=head1 MEMORY

Tensors are allocated from their context's memory arena:

=over 4

=item * Metadata: ~256 bytes per tensor

=item * Data: type-specific (4 bytes per element for F32)

=back

Memory is freed when the context is destroyed, not when individual
tensor objects go out of scope.

=head1 SEE ALSO

L<Lugh>, L<Lugh::Context>, L<Lugh::Ops>, L<Lugh::Graph>

L<https://github.com/ggerganov/ggml> - ggml tensor library

=head1 AUTHOR

lnation E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
