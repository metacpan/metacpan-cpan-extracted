#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Lugh;

# Test basic autograd tensor creation and management

plan tests => 20;

# Create context for tensors
my $ctx = Lugh::Context->new(mem_size => 1024 * 1024);
ok($ctx, 'Created context');

# Test 1: Create autograd tensor without requires_grad
my $t1 = Lugh::Autograd::Tensor->new($ctx, 'f32', 4);
ok($t1, 'Created autograd tensor without requires_grad');
ok(!$t1->requires_grad, 'requires_grad is false by default');

# Test 2: Create autograd tensor with requires_grad
my $t2 = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
ok($t2, 'Created autograd tensor with requires_grad');
ok($t2->requires_grad, 'requires_grad is true when set');

# Test 3: Check tensor is leaf by default
ok($t2->is_leaf, 'Tensor is leaf by default');

# Test 4: Check tensor ID
my $id = $t2->id;
ok($id > 0, 'Tensor has valid ID');

# Test 5: Set and get data
$t2->set_data(1.0, 2.0, 3.0, 4.0);
my @data = $t2->get_data;
is(scalar(@data), 4, 'Got 4 elements back');
is($data[0], 1.0, 'First element is 1.0');
is($data[3], 4.0, 'Last element is 4.0');

# Test 6: Check shape
my @shape = $t2->shape;
is(scalar(@shape), 1, 'Shape has 1 dimension');
is($shape[0], 4, 'First dimension is 4');

# Test 7: Check nelements
is($t2->nelements, 4, 'nelements is 4');

# Test 8: Check grad initially (should be all zeros)
my $grad = $t2->grad;
ok(ref($grad) eq 'ARRAY', 'grad returns array reference');
is(scalar(@$grad), 4, 'Gradient has 4 elements');
is($grad->[0], 0.0, 'Initial gradient is 0');

# Test 9: zero_grad
$t2->zero_grad;
$grad = $t2->grad;
is($grad->[0], 0.0, 'Gradient is 0 after zero_grad');

# Test 10: Modify requires_grad
$t1->requires_grad(1);
ok($t1->requires_grad, 'Can set requires_grad to true');
ok(defined $t1->grad, 'Gradient tensor allocated after setting requires_grad');

# Test 11: Create 2D tensor
my $t3 = Lugh::Autograd::Tensor->new($ctx, 'f32', 3, 4, { requires_grad => 1 });
ok($t3, 'Created 2D autograd tensor');

done_testing();
