#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Lugh;

# Test Lugh::Autograd::Tensor - validates all documented examples

plan tests => 35;

# ============================================================================
# Basic Construction (from SYNOPSIS)
# ============================================================================

my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
ok($ctx, 'Created context');

# Create a tensor without gradient tracking
my $x = Lugh::Autograd::Tensor->new($ctx, 'f32', 4);
ok($x, 'Created tensor without gradient tracking');
$x->set_data(1.0, 2.0, 3.0, 4.0);

# Create a tensor with gradient tracking
my $w = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
ok($w, 'Created tensor with requires_grad');
$w->set_data(0.1, 0.2, 0.3, 0.4);

# Check gradient tracking status (from SYNOPSIS)
ok($w->requires_grad, 'requires_grad returns true when set');
ok($w->is_leaf, 'is_leaf returns true for directly created tensor');

# Get tensor properties (from SYNOPSIS)
my @shape = $w->shape;
is_deeply(\@shape, [4], 'shape returns (4) for 1D tensor');

my $n = $w->nelements;
is($n, 4, 'nelements returns 4');

my @data = $w->get_data;
is(scalar @data, 4, 'get_data returns 4 values');
# Use tolerance for float comparison
ok(abs($data[0] - 0.1) < 0.001, 'get_data first value is ~0.1');

# ============================================================================
# Constructor Examples (from POD)
# ============================================================================

# 1D tensor with 10 elements
my $vec = Lugh::Autograd::Tensor->new($ctx, 'f32', 10);
ok($vec, 'Created 1D tensor with 10 elements');
is($vec->nelements, 10, '1D tensor has 10 elements');
is_deeply([$vec->shape], [10], '1D tensor shape is (10)');

# 2D tensor (matrix) 3x4
my $mat = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, 4);
ok($mat, 'Created 2D tensor 3x4');
is($mat->nelements, 12, '2D tensor has 12 elements');
is_deeply([$mat->shape], [3, 4], '2D tensor shape is (3, 4)');

# 3D tensor with gradient tracking
my $vol = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 3, 4, {
    requires_grad => 1,
});
ok($vol, 'Created 3D tensor with requires_grad');
is($vol->nelements, 24, '3D tensor has 24 elements');
is_deeply([$vol->shape], [2, 3, 4], '3D tensor shape is (2, 3, 4)');
ok($vol->requires_grad, '3D tensor requires_grad is true');

# 4D tensor (batch of images)
my $batch = Lugh::Autograd::Tensor->new($ctx, 'f32', 8, 3, 224, 224);
ok($batch, 'Created 4D tensor');
is($batch->nelements, 8 * 3 * 224 * 224, '4D tensor has correct element count');
is_deeply([$batch->shape], [8, 3, 224, 224], '4D tensor shape is (8, 3, 224, 224)');

# ============================================================================
# requires_grad getter/setter (from POD)
# ============================================================================

my $tensor = Lugh::Autograd::Tensor->new($ctx, 'f32', 4);
ok(!$tensor->requires_grad, 'New tensor has requires_grad = false');

$tensor->requires_grad(1);
ok($tensor->requires_grad, 'After setting, requires_grad = true');

$tensor->requires_grad(0);
ok(!$tensor->requires_grad, 'Can disable requires_grad');

# ============================================================================
# grad() method (from POD)
# ============================================================================

my $w2 = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, { requires_grad => 1 });
$w2->set_data(1.0, 2.0, 3.0);

my $grad = $w2->grad;
ok(ref($grad) eq 'ARRAY', 'grad() returns array reference');
is(scalar(@$grad), 3, 'grad has 3 elements');

# ============================================================================
# set_data with 2D tensor (from POD)
# ============================================================================

my $tensor2d = Lugh::Autograd::Tensor->new($ctx, 'f32', 2, 3);
$tensor2d->set_data(
    1.0, 2.0, 3.0,   # Row 0
    4.0, 5.0, 6.0,   # Row 1
);
my @data2d = $tensor2d->get_data;
is_deeply(\@data2d, [1, 2, 3, 4, 5, 6], 'set_data/get_data work for 2D tensor');

# ============================================================================
# zero_grad (from POD)
# ============================================================================

my $w3 = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
$w3->set_data(1.0, 2.0, 3.0, 4.0);

# Get initial gradient (should be zeros)
my $grad3 = $w3->grad;
is_deeply($grad3, [0, 0, 0, 0], 'Initial gradient is all zeros');

$w3->zero_grad;
$grad3 = $w3->grad;
is_deeply($grad3, [0, 0, 0, 0], 'Gradient is zeros after zero_grad');

# ============================================================================
# id() method
# ============================================================================

my $tensor_id = $w->id;
ok($tensor_id > 0, 'id() returns positive integer');

# ============================================================================
# Different data types
# ============================================================================

my $f16_tensor = Lugh::Autograd::Tensor->new($ctx, 'f16', 4);
ok($f16_tensor, 'Created f16 tensor');

my $i32_tensor = Lugh::Autograd::Tensor->new($ctx, 'i32', 4);
ok($i32_tensor, 'Created i32 tensor');

# ============================================================================
# Error cases
# ============================================================================

eval { Lugh::Autograd::Tensor->new($ctx, 'invalid', 4) };
ok($@, 'Invalid type throws exception');

eval { Lugh::Autograd::Tensor->new($ctx, 'f32', -1) };
ok($@, 'Negative dimension throws exception');

done_testing();
