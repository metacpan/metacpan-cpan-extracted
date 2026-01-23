package Lugh::Autograd::Ops;
use strict;
use warnings;

our $VERSION = '0.12';

# XS methods are loaded via Lugh.xs
# This module provides documentation only

1;

__END__

=head1 NAME

Lugh::Autograd::Ops - Differentiable operations for automatic differentiation

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Autograd;
    
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Create tensors with gradient tracking
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    $b->set_data(2.0, 2.0, 2.0, 2.0);
    
    # Element-wise operations
    my $sum_result = Lugh::Autograd::Ops->add($ctx, $a, $b);
    my $prod_result = Lugh::Autograd::Ops->mul($ctx, $a, $b);
    
    # Reduction operations
    my $total = Lugh::Autograd::Ops->sum($ctx, $prod_result);
    
    # Compute the graph
    my $graph = Lugh::Graph->new($ctx);
    my $raw = Lugh::Tensor->from_ptr($total->_raw_tensor_ptr);
    $graph->build_forward($raw);
    $graph->compute($ctx, 1);
    
    # Backward pass
    $total->backward;
    
    # Access gradients
    my $grad_a = $a->grad;  # Gradients w.r.t. $a
    my $grad_b = $b->grad;  # Gradients w.r.t. $b

=head1 DESCRIPTION

Lugh::Autograd::Ops provides differentiable tensor operations that automatically
track gradients for backpropagation. Each operation records its inputs in the
computation graph, enabling automatic gradient computation via the C<backward()>
method.

All operations return L<Lugh::Autograd::Tensor> objects. If any input tensor
has C<requires_grad> set to true and gradient tracking is enabled globally,
the output tensor will also track gradients.

=head1 CLASS METHODS

=head2 add

    my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);

Performs element-wise addition of two tensors.

B<Parameters:>

=over 4

=item * C<$ctx> - A L<Lugh::Context> object

=item * C<$a> - First L<Lugh::Autograd::Tensor> operand

=item * C<$b> - Second L<Lugh::Autograd::Tensor> operand

=back

B<Returns:> A new L<Lugh::Autograd::Tensor> containing C<$a + $b>

B<Gradient:> For C<z = x + y>, the gradients are:

    dL/dx = dL/dz
    dL/dy = dL/dz

B<Example:>

    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $y = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    
    $x->set_data(1.0, 2.0, 3.0);
    $y->set_data(4.0, 5.0, 6.0);
    
    my $z = Lugh::Autograd::Ops->add($ctx, $x, $y);
    $ctx->compute;
    
    # z contains [5.0, 7.0, 9.0]
    my @z_data = $z->get_data;
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $z);
    $ctx->compute;
    $loss->backward;
    
    # Both gradients are [1.0, 1.0, 1.0] (gradient of sum flows equally)
    my $grad_x = $x->grad;
    my $grad_y = $y->grad;

=head2 mul

    my $c = Lugh::Autograd::Ops->mul($ctx, $a, $b);

Performs element-wise multiplication of two tensors.

B<Parameters:>

=over 4

=item * C<$ctx> - A L<Lugh::Context> object

=item * C<$a> - First L<Lugh::Autograd::Tensor> operand

=item * C<$b> - Second L<Lugh::Autograd::Tensor> operand

=back

B<Returns:> A new L<Lugh::Autograd::Tensor> containing C<$a * $b>

B<Gradient:> For C<z = x * y>, the gradients are:

    dL/dx = dL/dz * y
    dL/dy = dL/dz * x

B<Example:>

    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $y = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    
    $x->set_data(2.0, 3.0, 4.0);
    $y->set_data(5.0, 6.0, 7.0);
    
    my $z = Lugh::Autograd::Ops->mul($ctx, $x, $y);
    $ctx->compute;
    
    # z contains [10.0, 18.0, 28.0]
    my @z_data = $z->get_data;
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $z);
    $ctx->compute;
    $loss->backward;
    
    # grad_x = y values = [5.0, 6.0, 7.0]
    # grad_y = x values = [2.0, 3.0, 4.0]
    my $grad_x = $x->grad;
    my $grad_y = $y->grad;

=head2 sum

    my $scalar = Lugh::Autograd::Ops->sum($ctx, $a);

Reduces a tensor to a scalar by summing all elements.

B<Parameters:>

=over 4

=item * C<$ctx> - A L<Lugh::Context> object

=item * C<$a> - The L<Lugh::Autograd::Tensor> to sum

=back

B<Returns:> A new L<Lugh::Autograd::Tensor> containing a single scalar value

B<Gradient:> For C<y = sum(x)>, the gradient is:

    dL/dx_i = dL/dy  (gradient broadcasts to all elements)

B<Example:>

    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $total = Lugh::Autograd::Ops->sum($ctx, $x);
    $ctx->compute;
    
    # total contains [10.0] (scalar tensor)
    my @total_data = $total->get_data;
    
    # Backward pass
    $total->backward;
    
    # All gradients are 1.0 (sum distributes gradient equally)
    my $grad = $x->grad;  # [1.0, 1.0, 1.0, 1.0]

=head2 sub

    my $c = Lugh::Autograd::Ops->sub($ctx, $a, $b);

Performs element-wise subtraction of two tensors.

B<Gradient:> For C<z = x - y>:

    dL/dx = dL/dz
    dL/dy = -dL/dz

=head2 div

    my $c = Lugh::Autograd::Ops->div($ctx, $a, $b);

Performs element-wise division of two tensors.

B<Gradient:> For C<z = x / y>:

    dL/dx = dL/dz / y
    dL/dy = -dL/dz * x / y^2

=head2 scale

    my $c = Lugh::Autograd::Ops->scale($ctx, $a, $scalar);

Multiplies all elements of a tensor by a scalar value.

B<Parameters:>

=over 4

=item * C<$ctx> - A L<Lugh::Context> object

=item * C<$a> - The L<Lugh::Autograd::Tensor> to scale

=item * C<$scalar> - A numeric scalar value

=back

B<Gradient:> For C<y = s * x>:

    dL/dx = s * dL/dy

=head2 matmul

    my $c = Lugh::Autograd::Ops->matmul($ctx, $a, $b);

Performs matrix multiplication of two tensors.

B<Gradient:> For C<C = A @ B>:

    dL/dA = dL/dC @ B^T
    dL/dB = A^T @ dL/dC

=head2 mean

    my $scalar = Lugh::Autograd::Ops->mean($ctx, $a);

Reduces a tensor to a scalar by computing the mean of all elements.

B<Gradient:> For C<y = mean(x)>:

    dL/dx_i = dL/dy / n  (where n is the number of elements)

=head2 relu

    my $c = Lugh::Autograd::Ops->relu($ctx, $a);

Applies the Rectified Linear Unit activation function element-wise.

B<Formula:> C<relu(x) = max(0, x)>

B<Gradient:>

    dL/dx = dL/dy if x > 0, else 0

=head2 gelu

    my $c = Lugh::Autograd::Ops->gelu($ctx, $a);

Applies the Gaussian Error Linear Unit activation function element-wise.

B<Formula:> C<gelu(x) = 0.5 * x * (1 + tanh(sqrt(2/pi) * (x + 0.044715 * x^3)))>

Used in transformer models like BERT and GPT.

=head2 silu

    my $c = Lugh::Autograd::Ops->silu($ctx, $a);

Applies the Sigmoid Linear Unit (Swish) activation function element-wise.

B<Formula:> C<silu(x) = x * sigmoid(x)>

Used in models like LLaMA and other modern architectures.

B<Gradient:>

    dL/dx = sigmoid(x) * (1 + x * (1 - sigmoid(x))) * dL/dy

=head2 softmax

    my $c = Lugh::Autograd::Ops->softmax($ctx, $a);

Applies the softmax function, converting logits to probabilities.

B<Formula:> C<softmax(x)_i = exp(x_i) / sum(exp(x_j))>

Output values are in range (0, 1) and sum to 1.

B<Gradient:>

    dL/dx_i = y_i * (dL/dy_i - sum_j(dL/dy_j * y_j))

=head2 rms_norm

    my $c = Lugh::Autograd::Ops->rms_norm($ctx, $a);
    my $c = Lugh::Autograd::Ops->rms_norm($ctx, $a, $eps);  # custom epsilon

Applies Root Mean Square Layer Normalization.

B<Formula:> C<rms_norm(x) = x / sqrt(mean(x^2) + eps)>

B<Parameters:>

=over 4

=item * C<$eps> - (Optional) Small constant for numerical stability, default 1e-5

=back

Used in transformer models like LLaMA for efficient normalization.

=head1 GRADIENT TRACKING

Operations respect the global gradient tracking state controlled by
L<Lugh::Autograd>:

    use Lugh::Autograd;
    
    # Gradients tracked normally
    my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);
    
    # Disable gradient tracking for efficiency
    Lugh::Autograd::no_grad {
        my $inference = Lugh::Autograd::Ops->add($ctx, $a, $b);
        # $inference->requires_grad is false
    };

When gradient tracking is disabled:

=over 4

=item * Output tensors have C<requires_grad = 0>

=item * No computation graph is built

=item * Memory usage is reduced

=back

=head1 COMPUTATION WORKFLOW

The typical workflow for using autograd operations is:

    # 1. Create context and tensors
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 10, { requires_grad => 1 });
    
    # 2. Set input data
    $x->set_data(1.0, 2.0, 3.0, ...);
    
    # 3. Build computation graph (forward pass)
    my $y = Lugh::Autograd::Ops->mul($ctx, $x, $x);  # x^2
    my $loss = Lugh::Autograd::Ops->sum($ctx, $y);
    
    # 4. Execute the computation
    $ctx->compute;
    
    # 5. Read forward pass results
    my @loss_val = $loss->get_data;
    
    # 6. Compute gradients (backward pass)
    $loss->backward;
    
    # 7. Read gradients
    my $grad = $x->grad;  # Contains 2*x for each element

=head1 CHAINING OPERATIONS

Operations can be chained to build complex computation graphs:

    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    $w->set_data(0.5, 0.5, 0.5, 0.5);
    $b->set_data(0.1, 0.1, 0.1, 0.1);
    
    # Linear layer: y = w * x + b
    my $wx = Lugh::Autograd::Ops->mul($ctx, $w, $x);
    my $y = Lugh::Autograd::Ops->add($ctx, $wx, $b);
    my $loss = Lugh::Autograd::Ops->sum($ctx, $y);
    
    $ctx->compute;
    $loss->backward;
    
    # All leaf tensors now have gradients computed
    my $grad_x = $x->grad;
    my $grad_w = $w->grad;
    my $grad_b = $b->grad;

=head1 ERROR HANDLING

Operations will die with an error message if:

=over 4

=item * The context is invalid or has been freed

=item * Input tensors are not valid L<Lugh::Autograd::Tensor> objects

=item * Input tensors have been freed

=item * Tensor shapes are incompatible for the operation

=back

    eval {
        my $result = Lugh::Autograd::Ops->add($ctx, $a, $b);
    };
    if ($@) {
        warn "Operation failed: $@";
    }

=head1 SEE ALSO

=over 4

=item * L<Lugh::Autograd> - Main autograd module with gradient context management

=item * L<Lugh::Autograd::Tensor> - Tensor class with gradient support

=item * L<Lugh::Context> - Memory context for tensor operations

=item * L<Lugh::Tensor> - Base tensor class

=back

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
