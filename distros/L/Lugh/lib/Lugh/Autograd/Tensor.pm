package Lugh::Autograd::Tensor;
use strict;
use warnings;
use Lugh;

our $VERSION = '0.12';

=head1 NAME

Lugh::Autograd::Tensor - Tensor with automatic differentiation support

=head1 SYNOPSIS

    use Lugh;
    
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Create a tensor without gradient tracking
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4);
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    
    # Create a tensor with gradient tracking
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $w->set_data(0.1, 0.2, 0.3, 0.4);
    
    # Check gradient tracking status
    print "requires_grad: ", $w->requires_grad, "\n";  # 1
    print "is_leaf: ", $w->is_leaf, "\n";              # 1
    
    # Get tensor properties
    my @shape = $w->shape;           # (4)
    my $n = $w->nelements;           # 4
    my @data = $w->get_data;         # (0.1, 0.2, 0.3, 0.4)
    
    # After backward pass, access gradients
    my $grad = $w->grad;             # Array reference or undef
    
    # Zero gradients before next iteration
    $w->zero_grad;

=head1 DESCRIPTION

C<Lugh::Autograd::Tensor> provides tensors with automatic differentiation
support for training neural networks. Each tensor can optionally track
gradients, building a dynamic computation graph that enables efficient
backpropagation.

Tensors created with C<requires_grad =E<gt> 1> will:

=over 4

=item * Track operations performed on them

=item * Allocate storage for gradients

=item * Participate in backward passes

=back

=head1 CONSTRUCTOR

=head2 new

    my $tensor = Lugh::Autograd::Tensor->new($ctx, $type, @dims, \%options);

Creates a new autograd tensor.

B<Parameters:>

=over 4

=item C<$ctx>

A L<Lugh::Context> object that manages memory for the tensor.

=item C<$type>

Data type string. Supported values:

=over 4

=item * C<'f32'> - 32-bit floating point (most common)

=item * C<'f16'> - 16-bit floating point (memory efficient)

=item * C<'i32'> - 32-bit integer

=back

=item C<@dims>

One to four dimension sizes. All must be positive integers.

=item C<\%options>

Optional hash reference with:

=over 4

=item C<requires_grad>

Boolean. If true, the tensor will track gradients.

=back

=back

B<Returns:> A new C<Lugh::Autograd::Tensor> object.

B<Examples:>

    # 1D tensor with 10 elements
    my $vec = Lugh::Autograd::Tensor->new($ctx, 'f32', 10);
    
    # 2D tensor (matrix) 3x4
    my $mat = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, 4);
    
    # 3D tensor with gradient tracking
    my $vol = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 3, 4, {
        requires_grad => 1,
    });
    
    # 4D tensor (batch of images)
    my $batch = Lugh::Autograd::Tensor->new($ctx, 'f32', 8, 3, 224, 224);

=head1 METHODS

=head2 id

    my $tensor_id = $tensor->id;

Returns the internal tensor ID used for registry tracking.

B<Returns:> Integer ID, or -1 if invalid.

=head2 requires_grad

    # Getter
    my $tracking = $tensor->requires_grad;
    
    # Setter
    $tensor->requires_grad(1);  # Enable gradient tracking
    $tensor->requires_grad(0);  # Disable gradient tracking

Gets or sets whether this tensor tracks gradients.

When enabling gradient tracking on a tensor that didn't have it,
the gradient storage will be automatically allocated.

B<Parameters:> Optional boolean value to set.

B<Returns:> Current gradient tracking status (boolean).

B<Example:>

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 4);
    print $tensor->requires_grad;  # 0
    
    $tensor->requires_grad(1);
    print $tensor->requires_grad;  # 1

=head2 grad

    my $gradient = $tensor->grad;

Returns the accumulated gradient for this tensor.

B<Returns:> Array reference containing gradient values, or C<undef>
if no gradient has been computed or the tensor doesn't require gradients.

B<Example:>

    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $w->set_data(1.0, 2.0, 3.0);
    
    # ... perform operations and call backward() ...
    
    my $grad = $w->grad;
    if (defined $grad) {
        print "Gradients: @$grad\n";
    }

=head2 zero_grad

    $tensor->zero_grad;

Zeros out the accumulated gradient. Call this before each training
iteration to prevent gradient accumulation across batches.

B<Example:>

    for my $epoch (1..100) {
        $w->zero_grad;  # Clear gradients from previous iteration
        
        # Forward pass
        my $loss = compute_loss($w, $data);
        
        # Backward pass
        $loss->backward;
        
        # Update weights using gradients
        update_weights($w);
    }

=head2 set_data

    $tensor->set_data(@values);

Sets the tensor's data values. The number of values must exactly
match the tensor's total element count.

B<Parameters:> List of numeric values.

B<Throws:> Exception if the number of values doesn't match C<nelements()>.

B<Example:>

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 3);
    $tensor->set_data(
        1.0, 2.0, 3.0,   # Row 0
        4.0, 5.0, 6.0,   # Row 1
    );

=head2 get_data

    my @values = $tensor->get_data;

Retrieves all tensor data as a flat list.

B<Returns:> List of numeric values in row-major order.

B<Example:>

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 2);
    $tensor->set_data(1, 2, 3, 4);
    
    my @data = $tensor->get_data;
    print "@data\n";  # 1 2 3 4

=head2 nelements

    my $count = $tensor->nelements;

Returns the total number of elements in the tensor.

B<Returns:> Integer element count.

B<Example:>

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, 4, 5);
    print $tensor->nelements;  # 60

=head2 shape

    my @dims = $tensor->shape;

Returns the tensor's dimensions.

B<Returns:> List of dimension sizes.

B<Example:>

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, 4, 5);
    my @shape = $tensor->shape;
    print "@shape\n";  # 3 4 5

=head2 is_leaf

    my $leaf = $tensor->is_leaf;

Returns whether this tensor is a leaf in the computation graph.

Leaf tensors are those created directly (not as the output of an
operation). Only leaf tensors retain gradients after C<backward()>.

B<Returns:> Boolean.

B<Example:>

    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    print $a->is_leaf;  # 1 (created directly)
    
    my $b = Lugh::Autograd::Ops->sum($ctx, $a);
    print $b->is_leaf;  # 0 (result of operation)

=head2 backward

    $tensor->backward;
    $tensor->backward(@grad_output);

Computes gradients through backpropagation from this tensor.

For scalar tensors (e.g., loss values), call without arguments.
The gradient is implicitly set to 1.0.

For non-scalar tensors, provide the gradient of the downstream
loss with respect to this tensor.

B<Parameters:> Optional list of gradient values for non-scalar outputs.

B<Throws:> Exception if the tensor doesn't require gradients.

B<Example:>

    # Scalar loss
    my $loss = Lugh::Autograd::Ops->sum($ctx, $output);
    $loss->backward;  # Gradient = 1.0
    
    # Non-scalar output
    my $output = Lugh::Autograd::Ops->mul($ctx, $a, $b);
    $output->backward(1.0, 1.0, 1.0, 1.0);  # Provide gradient

=head2 _raw_tensor_ptr

    my $ptr = $tensor->_raw_tensor_ptr;

Returns the raw pointer to the underlying GGML tensor. This is
primarily for internal use and interoperability with C<Lugh::Ops>
and C<Lugh::Graph>.

B<Returns:> Integer pointer value.

B<Warning:> This is a low-level method. The returned pointer is
only valid while the tensor exists.

=head1 GRADIENT TRACKING

Gradient tracking is controlled by two mechanisms:

=over 4

=item 1. Per-tensor C<requires_grad> flag

=item 2. Global gradient enabled state (see L<Lugh::Autograd>)

=back

A tensor will only accumulate gradients if both:

=over 4

=item * Its C<requires_grad> is true

=item * C<Lugh::Autograd::is_grad_enabled()> returns true

=back

=head1 MEMORY MANAGEMENT

Tensors are automatically cleaned up when they go out of scope.
The tensor data and gradient storage are managed by the associated
L<Lugh::Context>, so ensure the context outlives all tensors
created from it.

=head1 SEE ALSO

L<Lugh::Autograd> - Gradient context management and utilities

L<Lugh::Autograd::Ops> - Operations with gradient tracking

L<Lugh::Context> - Memory context management

L<Lugh::Tensor> - Basic tensor without autograd

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
