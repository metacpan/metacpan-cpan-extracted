#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Lugh;

# Test autograd forward and backward operations

plan tests => 25;

# Create context with enough memory for operations
my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
ok($ctx, 'Created context');

# Test 1: Simple addition forward pass
my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
ok($a && $b, 'Created two tensors with requires_grad');

$a->set_data(1.0, 2.0, 3.0, 4.0);
$b->set_data(0.5, 1.0, 1.5, 2.0);

# Test 2: Add operation
my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);
ok($c, 'Created add result');
ok(!$c->is_leaf, 'Result of add is not a leaf');
ok($c->requires_grad, 'Result inherits requires_grad');

# Compute the graph to get actual values
my $graph = Lugh::Graph->new($ctx);
my $raw_c = Lugh::Tensor->from_ptr($c->_raw_tensor_ptr);
$graph->build_forward($raw_c);
$graph->compute($ctx, 1);

# Check forward pass result
my @c_data = $c->get_data;
is($c_data[0], 1.5, 'add: 1.0 + 0.5 = 1.5');
is($c_data[1], 3.0, 'add: 2.0 + 1.0 = 3.0');
is($c_data[2], 4.5, 'add: 3.0 + 1.5 = 4.5');
is($c_data[3], 6.0, 'add: 4.0 + 2.0 = 6.0');

# Test 3: Backward pass for add
$c->backward(1.0, 1.0, 1.0, 1.0);

my $grad_a = $a->grad;
my $grad_b = $b->grad;

ok(ref($grad_a) eq 'ARRAY', 'Got gradient for a');
ok(ref($grad_b) eq 'ARRAY', 'Got gradient for b');

# For add: d(a+b)/da = 1, d(a+b)/db = 1
is($grad_a->[0], 1.0, 'd(a+b)/da = 1');
is($grad_b->[0], 1.0, 'd(a+b)/db = 1');

# Test 4: Multiplication with gradient tracking
$a->zero_grad;
$b->zero_grad;

my $d = Lugh::Autograd::Ops->mul($ctx, $a, $b);
ok($d, 'Created mul result');
ok($d->requires_grad, 'mul result requires grad');

# Compute forward pass
my $graph2 = Lugh::Graph->new($ctx);
my $raw_d = Lugh::Tensor->from_ptr($d->_raw_tensor_ptr);
$graph2->build_forward($raw_d);
$graph2->compute($ctx, 1);

my @d_data = $d->get_data;
is($d_data[0], 0.5, 'mul: 1.0 * 0.5 = 0.5');
is($d_data[1], 2.0, 'mul: 2.0 * 1.0 = 2.0');

# Backward pass for mul
$d->backward(1.0, 1.0, 1.0, 1.0);

$grad_a = $a->grad;
$grad_b = $b->grad;

# For mul: d(a*b)/da = b, d(a*b)/db = a
is($grad_a->[0], 0.5, 'd(a*b)/da = b = 0.5');
is($grad_a->[1], 1.0, 'd(a*b)/da = b = 1.0');
is($grad_b->[0], 1.0, 'd(a*b)/db = a = 1.0');
is($grad_b->[1], 2.0, 'd(a*b)/db = a = 2.0');

# Test 5: Sum operation
$a->zero_grad;

my $sum = Lugh::Autograd::Ops->sum($ctx, $a);
ok($sum, 'Created sum result');

# Compute forward pass
my $graph3 = Lugh::Graph->new($ctx);
my $raw_sum = Lugh::Tensor->from_ptr($sum->_raw_tensor_ptr);
$graph3->build_forward($raw_sum);
$graph3->compute($ctx, 1);

my @sum_data = $sum->get_data;
is($sum_data[0], 10.0, 'sum: 1+2+3+4 = 10');

# Backward pass for sum
$sum->backward;

$grad_a = $a->grad;

# For sum: d(sum(a))/da_i = 1 for all i
is($grad_a->[0], 1.0, 'd(sum)/da[0] = 1');
is($grad_a->[3], 1.0, 'd(sum)/da[3] = 1');

done_testing();
