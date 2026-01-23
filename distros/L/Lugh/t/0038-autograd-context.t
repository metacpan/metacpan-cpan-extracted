#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Lugh;
use Lugh::Autograd;

# Test gradient context management

plan tests => 12;

my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
ok($ctx, 'Created context');

# Test 1: Gradient tracking is enabled by default
ok(Lugh::Autograd::is_grad_enabled(), 'Gradient tracking enabled by default');

# Test 2: Create tensor with requires_grad
my $a = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
my $b = Lugh::Autograd::Tensor->new($ctx, 'f32', 4, { requires_grad => 1 });
$a->set_data(1.0, 2.0, 3.0, 4.0);
$b->set_data(0.5, 1.0, 1.5, 2.0);
ok($a->requires_grad, 'Tensor a requires grad');
ok($b->requires_grad, 'Tensor b requires grad');

# Test 3: Operation with grad enabled tracks gradients
my $c = Lugh::Autograd::Ops->add($ctx, $a, $b);
ok($c->requires_grad, 'Result has requires_grad when grad enabled');
ok(!$c->is_leaf, 'Result is not a leaf when grad enabled');

# Test 4: no_grad disables gradient tracking
my $d;
Lugh::Autograd::no_grad {
    ok(!Lugh::Autograd::is_grad_enabled(), 'Grad disabled inside no_grad block');
    $d = Lugh::Autograd::Ops->add($ctx, $a, $b);
    ok(!$d->requires_grad, 'Result does not require grad inside no_grad');
};

# Test 5: Gradient tracking restored after no_grad
ok(Lugh::Autograd::is_grad_enabled(), 'Grad restored after no_grad block');

# Test 6: set_grad_enabled returns previous state
my $prev = Lugh::Autograd::set_grad_enabled(0);
ok($prev, 'set_grad_enabled returned previous state (true)');
ok(!Lugh::Autograd::is_grad_enabled(), 'Grad now disabled');

# Restore
Lugh::Autograd::set_grad_enabled(1);
ok(Lugh::Autograd::is_grad_enabled(), 'Grad restored via set_grad_enabled');

done_testing();
