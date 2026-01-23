package Lugh::Autograd;
use strict;
use warnings;
use Lugh;

our $VERSION = '0.12';

=head1 NAME

Lugh::Autograd - Automatic differentiation for Lugh tensors

=head1 SYNOPSIS

    use Lugh;
    use Lugh::Autograd;
    
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Create tensors with gradient tracking
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    $b->set_data(0.5, 1.0, 1.5, 2.0);
    
    # Forward pass
    my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    
    # Backward pass
    $loss->backward();
    
    # Access gradients
    my $grad_a = $a->grad;  # [1, 1, 1, 1]
    my $grad_b = $b->grad;  # [1, 1, 1, 1]
    
    # Disable gradient tracking temporarily
    Lugh::Autograd::no_grad {
        my $inference_result = Lugh::Autograd::Ops->add($ctx, $a, $b);
        # No gradient tracking, more memory efficient
    };

=head1 DESCRIPTION

Lugh::Autograd provides automatic differentiation capabilities for training
neural networks. It implements a dynamic computation graph that tracks
operations and enables efficient gradient computation through backpropagation.

=head1 FUNCTIONS

=head2 is_grad_enabled

    my $enabled = Lugh::Autograd::is_grad_enabled();

Returns true if gradient tracking is currently enabled.

=head2 set_grad_enabled

    my $prev = Lugh::Autograd::set_grad_enabled($enabled);

Enable or disable gradient tracking. Returns the previous state.

=head2 no_grad

    Lugh::Autograd::no_grad {
        # Gradient tracking disabled in this block
        my $result = Lugh::Autograd::Ops->add($ctx, $a, $b);
    };

Executes a code block with gradient tracking disabled. The previous
gradient tracking state is restored after the block completes.

=head1 CLASSES

=head2 Lugh::Autograd::Tensor

Tensor with gradient tracking support.

=head3 new($ctx, $type, @dims, \%options)

Create a new autograd tensor.

    my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 10, 20, {
        requires_grad => 1,
    });

=head3 requires_grad([$value])

Get or set whether this tensor requires gradient tracking.

=head3 grad()

Returns the gradient as an array reference, or undef if no gradient.

=head3 zero_grad()

Zeros out the accumulated gradient.

=head3 backward([@grad_output])

Performs backpropagation from this tensor. For scalar losses, no arguments
are needed. For non-scalar outputs, provide the gradient values.

=head3 is_leaf()

Returns true if this tensor is a leaf (created directly, not as output
of an operation).

=head3 set_data(@values)

Set tensor data values.

=head3 get_data()

Get tensor data values as a list.

=head3 shape()

Returns the tensor dimensions as a list.

=head3 nelements()

Returns the total number of elements.

=head2 Lugh::Autograd::Ops

Operations that track gradients.

=head3 add($ctx, $a, $b)

Element-wise addition.

=head3 mul($ctx, $a, $b)

Element-wise multiplication.

=head3 sum($ctx, $a)

Sum all elements to a scalar.

=head1 AUTHOR

LNATION <email@lnation.org>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

# no_grad context manager
sub no_grad (&) {
    my $code = shift;
    
    my $prev = Lugh::Autograd::is_grad_enabled();
    Lugh::Autograd::set_grad_enabled(0);
    
    my $error;
    my @result;
    my $wantarray = wantarray;
    
    eval {
        if ($wantarray) {
            @result = $code->();
        } elsif (defined $wantarray) {
            $result[0] = $code->();
        } else {
            $code->();
        }
    };
    $error = $@;
    
    Lugh::Autograd::set_grad_enabled($prev);
    
    die $error if $error;
    
    return $wantarray ? @result : $result[0];
}

# enable_grad context manager (opposite of no_grad)
sub enable_grad (&) {
    my $code = shift;
    
    my $prev = Lugh::Autograd::is_grad_enabled();
    Lugh::Autograd::set_grad_enabled(1);
    
    my $error;
    my @result;
    my $wantarray = wantarray;
    
    eval {
        if ($wantarray) {
            @result = $code->();
        } elsif (defined $wantarray) {
            $result[0] = $code->();
        } else {
            $code->();
        }
    };
    $error = $@;
    
    Lugh::Autograd::set_grad_enabled($prev);
    
    die $error if $error;
    
    return $wantarray ? @result : $result[0];
}

1;
