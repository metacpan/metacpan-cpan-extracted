#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';

# Test Lugh::Autograd::Ops module documentation examples
# This validates all examples in the POD are correct

BEGIN {
    use_ok('Lugh');
    use_ok('Lugh::Autograd');
}

# Helper for float comparison
sub float_eq {
    my ($a, $b, $tolerance) = @_;
    $tolerance //= 0.001;
    return abs($a - $b) < $tolerance;
}

# Helper to compute a tensor result
sub compute_tensor {
    my ($ctx, $tensor) = @_;
    my $graph = Lugh::Graph->new($ctx);
    my $raw = Lugh::Tensor->from_ptr($tensor->_raw_tensor_ptr);
    $graph->build_forward($raw);
    $graph->compute($ctx, 1);
}

# =============================================================================
# SYNOPSIS EXAMPLE
# =============================================================================

subtest 'SYNOPSIS example' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    ok($ctx, 'Created context');
    
    # Create tensors with gradient tracking
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    $b->set_data(2.0, 2.0, 2.0, 2.0);
    
    # Element-wise operations
    my $sum_result = Lugh::Autograd::Ops->add($ctx, $a, $b);
    ok($sum_result, 'add() returned a tensor');
    
    my $prod_result = Lugh::Autograd::Ops->mul($ctx, $a, $b);
    ok($prod_result, 'mul() returned a tensor');
    
    # Reduction operations
    my $total = Lugh::Autograd::Ops->sum($ctx, $prod_result);
    ok($total, 'sum() returned a tensor');
    
    # Compute result
    compute_tensor($ctx, $total);
    $total->backward;
    
    # Access gradients
    my $grad_a = $a->grad;
    my $grad_b = $b->grad;
    
    ok($grad_a, 'Got gradient for $a');
    ok($grad_b, 'Got gradient for $b');
};

# =============================================================================
# add() EXAMPLE
# =============================================================================

subtest 'add() example' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $y = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    
    $x->set_data(1.0, 2.0, 3.0);
    $y->set_data(4.0, 5.0, 6.0);
    
    my $z = Lugh::Autograd::Ops->add($ctx, $x, $y);
    compute_tensor($ctx, $z);
    
    # z contains [5.0, 7.0, 9.0]
    my @z_data = $z->get_data;
    is(scalar @z_data, 3, 'z has 3 elements');
    ok(float_eq($z_data[0], 5.0), 'z[0] = 5.0');
    ok(float_eq($z_data[1], 7.0), 'z[1] = 7.0');
    ok(float_eq($z_data[2], 9.0), 'z[2] = 9.0');
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $z);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    # Both gradients are [1.0, 1.0, 1.0] (gradient of sum flows equally)
    my $grad_x = $x->grad;
    my $grad_y = $y->grad;
    
    is(scalar @$grad_x, 3, 'grad_x has 3 elements');
    is(scalar @$grad_y, 3, 'grad_y has 3 elements');
    
    for my $i (0..2) {
        ok(float_eq($grad_x->[$i], 1.0), "grad_x[$i] = 1.0");
        ok(float_eq($grad_y->[$i], 1.0), "grad_y[$i] = 1.0");
    }
};

# =============================================================================
# mul() EXAMPLE
# =============================================================================

subtest 'mul() example' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $y = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    
    $x->set_data(2.0, 3.0, 4.0);
    $y->set_data(5.0, 6.0, 7.0);
    
    my $z = Lugh::Autograd::Ops->mul($ctx, $x, $y);
    compute_tensor($ctx, $z);
    
    # z contains [10.0, 18.0, 28.0]
    my @z_data = $z->get_data;
    is(scalar @z_data, 3, 'z has 3 elements');
    ok(float_eq($z_data[0], 10.0), 'z[0] = 10.0 (2*5)');
    ok(float_eq($z_data[1], 18.0), 'z[1] = 18.0 (3*6)');
    ok(float_eq($z_data[2], 28.0), 'z[2] = 28.0 (4*7)');
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $z);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    # grad_x = y values = [5.0, 6.0, 7.0]
    # grad_y = x values = [2.0, 3.0, 4.0]
    my $grad_x = $x->grad;
    my $grad_y = $y->grad;
    
    is(scalar @$grad_x, 3, 'grad_x has 3 elements');
    is(scalar @$grad_y, 3, 'grad_y has 3 elements');
    
    ok(float_eq($grad_x->[0], 5.0), 'grad_x[0] = 5.0 (y[0])');
    ok(float_eq($grad_x->[1], 6.0), 'grad_x[1] = 6.0 (y[1])');
    ok(float_eq($grad_x->[2], 7.0), 'grad_x[2] = 7.0 (y[2])');
    
    ok(float_eq($grad_y->[0], 2.0), 'grad_y[0] = 2.0 (x[0])');
    ok(float_eq($grad_y->[1], 3.0), 'grad_y[1] = 3.0 (x[1])');
    ok(float_eq($grad_y->[2], 4.0), 'grad_y[2] = 4.0 (x[2])');
};

# =============================================================================
# sum() EXAMPLE
# =============================================================================

subtest 'sum() example' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $total = Lugh::Autograd::Ops->sum($ctx, $x);
    compute_tensor($ctx, $total);
    
    # total contains [10.0] (scalar tensor)
    my @total_data = $total->get_data;
    is(scalar @total_data, 1, 'total has 1 element (scalar)');
    ok(float_eq($total_data[0], 10.0), 'sum = 10.0 (1+2+3+4)');
    
    # Backward pass
    $total->backward;
    
    # All gradients are 1.0 (sum distributes gradient equally)
    my $grad = $x->grad;  # [1.0, 1.0, 1.0, 1.0]
    
    is(scalar @$grad, 4, 'grad has 4 elements');
    for my $i (0..3) {
        ok(float_eq($grad->[$i], 1.0), "grad[$i] = 1.0");
    }
};

# =============================================================================
# GRADIENT TRACKING EXAMPLE
# =============================================================================

subtest 'gradient tracking with no_grad' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0);
    $b->set_data(4.0, 5.0, 6.0);
    
    # Gradients tracked normally
    my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);
    ok($c->requires_grad, 'Normal: output requires_grad is true');
    
    # Disable gradient tracking for efficiency
    Lugh::Autograd::no_grad {
        my $inference = Lugh::Autograd::Ops->add($ctx, $a, $b);
        ok(!$inference->requires_grad, 'no_grad: output requires_grad is false');
    };
    
    # Back to normal tracking
    my $d = Lugh::Autograd::Ops->add($ctx, $a, $b);
    ok($d->requires_grad, 'After no_grad: output requires_grad is true again');
};

# =============================================================================
# COMPUTATION WORKFLOW EXAMPLE
# =============================================================================

subtest 'computation workflow' => sub {
    # 1. Create context and tensors
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    # 2. Set input data
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    
    # 3. Build computation graph (forward pass)
    my $y = Lugh::Autograd::Ops->mul($ctx, $x, $x);  # x^2
    my $loss = Lugh::Autograd::Ops->sum($ctx, $y);
    
    # 4. Execute the computation
    compute_tensor($ctx, $loss);
    
    # 5. Read forward pass results
    my @loss_val = $loss->get_data;
    # 1^2 + 2^2 + 3^2 + 4^2 = 1 + 4 + 9 + 16 = 30
    ok(float_eq($loss_val[0], 30.0), 'loss = 30.0 (sum of squares)');
    
    # 6. Compute gradients (backward pass)
    $loss->backward;
    
    # 7. Read gradients
    my $grad = $x->grad;  # Contains 2*x for each element
    
    is(scalar @$grad, 4, 'grad has 4 elements');
    ok(float_eq($grad->[0], 2.0), 'grad[0] = 2*1 = 2.0');
    ok(float_eq($grad->[1], 4.0), 'grad[1] = 2*2 = 4.0');
    ok(float_eq($grad->[2], 6.0), 'grad[2] = 2*3 = 6.0');
    ok(float_eq($grad->[3], 8.0), 'grad[3] = 2*4 = 8.0');
};

# =============================================================================
# CHAINING OPERATIONS EXAMPLE
# =============================================================================

subtest 'chaining operations (linear layer)' => sub {
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
    
    compute_tensor($ctx, $loss);
    
    # Verify forward pass
    # wx = [0.5, 1.0, 1.5, 2.0]
    # y = [0.6, 1.1, 1.6, 2.1]
    # loss = 5.4
    my @loss_val = $loss->get_data;
    ok(float_eq($loss_val[0], 5.4), 'loss = 5.4');
    
    $loss->backward;
    
    # All leaf tensors now have gradients computed
    my $grad_x = $x->grad;
    my $grad_w = $w->grad;
    my $grad_b = $b->grad;
    
    ok($grad_x, 'grad_x exists');
    ok($grad_w, 'grad_w exists');
    ok($grad_b, 'grad_b exists');
    
    # grad_b should be all 1s (gradient of sum through add)
    for my $i (0..3) {
        ok(float_eq($grad_b->[$i], 1.0), "grad_b[$i] = 1.0");
    }
    
    # grad_w should be x values (from mul gradient)
    ok(float_eq($grad_w->[0], 1.0), 'grad_w[0] = x[0] = 1.0');
    ok(float_eq($grad_w->[1], 2.0), 'grad_w[1] = x[1] = 2.0');
    ok(float_eq($grad_w->[2], 3.0), 'grad_w[2] = x[2] = 3.0');
    ok(float_eq($grad_w->[3], 4.0), 'grad_w[3] = x[3] = 4.0');
    
    # grad_x should be w values (from mul gradient)
    for my $i (0..3) {
        ok(float_eq($grad_x->[$i], 0.5), "grad_x[$i] = w[$i] = 0.5");
    }
};

# =============================================================================
# ERROR HANDLING EXAMPLE
# =============================================================================

subtest 'error handling' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0);
    
    # Try invalid operation - not a tensor
    eval {
        my $result = Lugh::Autograd::Ops->add($ctx, $a, "not a tensor");
    };
    ok($@, 'add() with non-tensor argument throws error');
    like($@, qr/must be an.*Tensor/i, 'Error message mentions tensor requirement');
    
    # Try sum with invalid argument
    eval {
        my $result = Lugh::Autograd::Ops->sum($ctx, { not => 'a tensor' });
    };
    ok($@, 'sum() with non-tensor argument throws error');
};

# =============================================================================
# OUTPUT TYPE
# =============================================================================

subtest 'output tensor type' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0);
    $b->set_data(4.0, 5.0, 6.0);
    
    my $add_result = Lugh::Autograd::Ops->add($ctx, $a, $b);
    isa_ok($add_result, 'Lugh::Autograd::Tensor', 'add() returns Lugh::Autograd::Tensor');
    
    my $mul_result = Lugh::Autograd::Ops->mul($ctx, $a, $b);
    isa_ok($mul_result, 'Lugh::Autograd::Tensor', 'mul() returns Lugh::Autograd::Tensor');
    
    my $sum_result = Lugh::Autograd::Ops->sum($ctx, $a);
    isa_ok($sum_result, 'Lugh::Autograd::Tensor', 'sum() returns Lugh::Autograd::Tensor');
};

done_testing();
