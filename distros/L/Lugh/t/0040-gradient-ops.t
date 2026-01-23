#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';

BEGIN {
    use_ok('Lugh');
    use_ok('Lugh::Autograd');
}

# Helper for float comparison
sub float_eq {
    my ($a, $b, $tolerance) = @_;
    $tolerance //= 0.01;
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
# SUB OPERATION
# =============================================================================

subtest 'sub() - subtraction with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $a->set_data(5.0, 6.0, 7.0, 8.0);
    $b->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $c = Lugh::Autograd::Ops->sub($ctx, $a, $b);
    ok($c, 'sub() created tensor');
    ok($c->requires_grad, 'sub result requires_grad');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    ok(float_eq($c_data[0], 4.0), 'sub: 5-1=4');
    ok(float_eq($c_data[1], 4.0), 'sub: 6-2=4');
    ok(float_eq($c_data[2], 4.0), 'sub: 7-3=4');
    ok(float_eq($c_data[3], 4.0), 'sub: 8-4=4');
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    my $grad_b = $b->grad;
    
    # d(a-b)/da = 1, d(a-b)/db = -1
    for my $i (0..3) {
        ok(float_eq($grad_a->[$i], 1.0), "grad_a[$i] = 1.0");
        ok(float_eq($grad_b->[$i], -1.0), "grad_b[$i] = -1.0");
    }
};

# =============================================================================
# DIV OPERATION
# =============================================================================

subtest 'div() - division with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    
    $a->set_data(8.0, 12.0, 20.0, 30.0);
    $b->set_data(2.0, 3.0, 4.0, 5.0);
    
    my $c = Lugh::Autograd::Ops->div($ctx, $a, $b);
    ok($c, 'div() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    ok(float_eq($c_data[0], 4.0), 'div: 8/2=4');
    ok(float_eq($c_data[1], 4.0), 'div: 12/3=4');
    ok(float_eq($c_data[2], 5.0), 'div: 20/4=5');
    ok(float_eq($c_data[3], 6.0), 'div: 30/5=6');
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    my $grad_b = $b->grad;
    
    # d(a/b)/da = 1/b
    ok(float_eq($grad_a->[0], 0.5), 'grad_a[0] = 1/2 = 0.5');
    ok(float_eq($grad_a->[1], 1.0/3.0), 'grad_a[1] = 1/3');
    
    # d(a/b)/db = -a/b^2
    ok(float_eq($grad_b->[0], -2.0), 'grad_b[0] = -8/4 = -2');
    ok(float_eq($grad_b->[1], -12.0/9.0), 'grad_b[1] = -12/9');
};

# =============================================================================
# SCALE OPERATION
# =============================================================================

subtest 'scale() - scalar multiplication with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $c = Lugh::Autograd::Ops->scale($ctx, $a, 2.5);
    ok($c, 'scale() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    ok(float_eq($c_data[0], 2.5), 'scale: 1.0*2.5=2.5');
    ok(float_eq($c_data[1], 5.0), 'scale: 2.0*2.5=5.0');
    ok(float_eq($c_data[2], 7.5), 'scale: 3.0*2.5=7.5');
    ok(float_eq($c_data[3], 10.0), 'scale: 4.0*2.5=10.0');
    
    # Backward pass
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    
    # d(a*s)/da = s
    for my $i (0..3) {
        ok(float_eq($grad_a->[$i], 2.5), "grad_a[$i] = 2.5");
    }
};

# =============================================================================
# RELU OPERATION
# =============================================================================

subtest 'relu() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 6, { requires_grad => 1 });
    $a->set_data(-2.0, -1.0, 0.0, 1.0, 2.0, 3.0);
    
    my $c = Lugh::Autograd::Ops->relu($ctx, $a);
    ok($c, 'relu() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    ok(float_eq($c_data[0], 0.0), 'relu(-2) = 0');
    ok(float_eq($c_data[1], 0.0), 'relu(-1) = 0');
    ok(float_eq($c_data[2], 0.0), 'relu(0) = 0');
    ok(float_eq($c_data[3], 1.0), 'relu(1) = 1');
    ok(float_eq($c_data[4], 2.0), 'relu(2) = 2');
    ok(float_eq($c_data[5], 3.0), 'relu(3) = 3');
    
    # Backward
    $c->backward(1.0, 1.0, 1.0, 1.0, 1.0, 1.0);
    
    my $grad_a = $a->grad;
    
    # d(relu)/dx = 0 if x <= 0, 1 if x > 0
    ok(float_eq($grad_a->[0], 0.0), 'grad_a[0] = 0 (x<0)');
    ok(float_eq($grad_a->[1], 0.0), 'grad_a[1] = 0 (x<0)');
    ok(float_eq($grad_a->[2], 0.0), 'grad_a[2] = 0 (x=0)');
    ok(float_eq($grad_a->[3], 1.0), 'grad_a[3] = 1 (x>0)');
    ok(float_eq($grad_a->[4], 1.0), 'grad_a[4] = 1 (x>0)');
    ok(float_eq($grad_a->[5], 1.0), 'grad_a[5] = 1 (x>0)');
};

# =============================================================================
# GELU OPERATION
# =============================================================================

subtest 'gelu() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(-1.0, 0.0, 1.0, 2.0);
    
    my $c = Lugh::Autograd::Ops->gelu($ctx, $a);
    ok($c, 'gelu() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    # GELU(-1) ≈ -0.159, GELU(0) = 0, GELU(1) ≈ 0.841, GELU(2) ≈ 1.955
    ok(float_eq($c_data[0], -0.159, 0.05), 'gelu(-1) ≈ -0.159');
    ok(float_eq($c_data[1], 0.0), 'gelu(0) = 0');
    ok(float_eq($c_data[2], 0.841, 0.05), 'gelu(1) ≈ 0.841');
    ok(float_eq($c_data[3], 1.955, 0.05), 'gelu(2) ≈ 1.955');
    
    # Backward
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    ok(defined $grad_a, 'gelu backward computed gradient');
    is(scalar @$grad_a, 4, 'gradient has 4 elements');
    
    # GELU'(0) ≈ 0.5, GELU'(1) ≈ 1.08
    ok(float_eq($grad_a->[1], 0.5, 0.05), "gelu'(0) ≈ 0.5");
    ok($grad_a->[2] > 0.9 && $grad_a->[2] < 1.2, "gelu'(1) in reasonable range");
};

# =============================================================================
# SILU OPERATION
# =============================================================================

subtest 'silu() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(-1.0, 0.0, 1.0, 2.0);
    
    my $c = Lugh::Autograd::Ops->silu($ctx, $a);
    ok($c, 'silu() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    # SiLU(x) = x * sigmoid(x)
    # SiLU(-1) ≈ -0.269, SiLU(0) = 0, SiLU(1) ≈ 0.731, SiLU(2) ≈ 1.762
    ok(float_eq($c_data[0], -0.269, 0.05), 'silu(-1) ≈ -0.269');
    ok(float_eq($c_data[1], 0.0), 'silu(0) = 0');
    ok(float_eq($c_data[2], 0.731, 0.05), 'silu(1) ≈ 0.731');
    ok(float_eq($c_data[3], 1.762, 0.05), 'silu(2) ≈ 1.762');
    
    # Backward
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    ok(defined $grad_a, 'silu backward computed gradient');
    is(scalar @$grad_a, 4, 'gradient has 4 elements');
    
    # SiLU'(0) = 0.5
    ok(float_eq($grad_a->[1], 0.5, 0.05), "silu'(0) ≈ 0.5");
};

# =============================================================================
# SOFTMAX OPERATION
# =============================================================================

subtest 'softmax() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $c = Lugh::Autograd::Ops->softmax($ctx, $a);
    ok($c, 'softmax() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    
    # Softmax outputs should sum to 1
    my $sum = 0;
    for my $v (@c_data) {
        $sum += $v;
        ok($v > 0 && $v < 1, "softmax element in (0,1)");
    }
    ok(float_eq($sum, 1.0, 0.01), 'softmax sums to 1');
    
    # Larger inputs -> larger softmax outputs
    ok($c_data[3] > $c_data[2], 'softmax(4) > softmax(3)');
    ok($c_data[2] > $c_data[1], 'softmax(3) > softmax(2)');
    ok($c_data[1] > $c_data[0], 'softmax(2) > softmax(1)');
    
    # Backward
    $c->backward(1.0, 0.0, 0.0, 0.0);
    
    my $grad_a = $a->grad;
    ok(defined $grad_a, 'softmax backward computed gradient');
    is(scalar @$grad_a, 4, 'gradient has 4 elements');
};

# =============================================================================
# RMS_NORM OPERATION
# =============================================================================

subtest 'rms_norm() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $c = Lugh::Autograd::Ops->rms_norm($ctx, $a);
    ok($c, 'rms_norm() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    is(scalar @c_data, 4, 'rms_norm output has 4 elements');
    
    # RMS norm should produce normalized values
    # rms = sqrt((1+4+9+16)/4) = sqrt(7.5) ≈ 2.739
    # normalized: [0.365, 0.730, 1.095, 1.460]
    ok(float_eq($c_data[0], 1.0/2.739, 0.05), 'rms_norm[0]');
    ok(float_eq($c_data[1], 2.0/2.739, 0.05), 'rms_norm[1]');
    
    # Backward
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    ok(defined $grad_a, 'rms_norm backward computed gradient');
    is(scalar @$grad_a, 4, 'gradient has 4 elements');
};

# =============================================================================
# MEAN OPERATION
# =============================================================================

subtest 'mean() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(2.0, 4.0, 6.0, 8.0);
    
    my $c = Lugh::Autograd::Ops->mean($ctx, $a);
    ok($c, 'mean() created tensor');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    ok(float_eq($c_data[0], 5.0), 'mean(2,4,6,8) = 5.0');
    
    # Backward
    $c->backward;
    
    my $grad_a = $a->grad;
    
    # d(mean)/da = 1/n for each element
    for my $i (0..3) {
        ok(float_eq($grad_a->[$i], 0.25), "grad_a[$i] = 1/4 = 0.25");
    }
};

# =============================================================================
# MATMUL OPERATION
# =============================================================================

subtest 'matmul() with gradients' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    # Simple matrix multiply - use vectors for simpler testing
    # ggml uses mul_mat(A, B) = A^T @ B for weight matrices
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 2, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 2, { requires_grad => 1 });
    
    # Identity matrix - should produce same output
    $a->set_data(1.0, 0.0, 0.0, 1.0);
    $b->set_data(1.0, 2.0, 3.0, 4.0);
    
    my $c = Lugh::Autograd::Ops->matmul($ctx, $a, $b);
    ok($c, 'matmul() created tensor');
    ok($c->requires_grad, 'matmul result requires_grad');
    
    compute_tensor($ctx, $c);
    
    my @c_data = $c->get_data;
    is(scalar @c_data, 4, 'matmul output has 4 elements');
    
    # With identity A, result should equal B
    ok(float_eq($c_data[0], 1.0), 'matmul result[0] correct');
    ok(float_eq($c_data[1], 2.0), 'matmul result[1] correct');
    ok(float_eq($c_data[2], 3.0), 'matmul result[2] correct');
    ok(float_eq($c_data[3], 4.0), 'matmul result[3] correct');
    
    # Backward
    my $loss = Lugh::Autograd::Ops->sum($ctx, $c);
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad_a = $a->grad;
    my $grad_b = $b->grad;
    
    ok(defined $grad_a, 'matmul backward computed grad_a');
    ok(defined $grad_b, 'matmul backward computed grad_b');
};

# =============================================================================
# CHAINED OPERATIONS
# =============================================================================

subtest 'chained gradient operations' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $x->set_data(1.0, 2.0, 3.0, 4.0);
    
    # Chain: scale -> relu -> sum
    my $scaled = Lugh::Autograd::Ops->scale($ctx, $x, 0.5);  # [0.5, 1, 1.5, 2]
    my $activated = Lugh::Autograd::Ops->relu($ctx, $scaled);
    my $loss = Lugh::Autograd::Ops->sum($ctx, $activated);
    
    compute_tensor($ctx, $loss);
    $loss->backward;
    
    my $grad = $x->grad;
    ok(defined $grad, 'chain backward computed gradient');
    
    # All values positive after scale, so relu passes gradient
    # d(sum(relu(0.5*x)))/dx = 0.5 for all x > 0
    for my $i (0..3) {
        ok(float_eq($grad->[$i], 0.5), "chained grad[$i] = 0.5");
    }
};

# =============================================================================
# OPERATIONS RETURN CORRECT TYPE
# =============================================================================

subtest 'all ops return Lugh::Autograd::Tensor' => sub {
    my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
    
    my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
    $a->set_data(1.0, 2.0, 3.0, 4.0);
    $b->set_data(1.0, 1.0, 1.0, 1.0);
    
    isa_ok(Lugh::Autograd::Ops->add($ctx, $a, $b), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->sub($ctx, $a, $b), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->mul($ctx, $a, $b), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->div($ctx, $a, $b), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->scale($ctx, $a, 2.0), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->relu($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->gelu($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->silu($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->softmax($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->rms_norm($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->sum($ctx, $a), 'Lugh::Autograd::Tensor');
    isa_ok(Lugh::Autograd::Ops->mean($ctx, $a), 'Lugh::Autograd::Tensor');
};

done_testing();
