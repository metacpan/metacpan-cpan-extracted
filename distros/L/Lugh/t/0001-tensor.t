#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok('Lugh') }

# Test version
is(Lugh::version(), '0.04', 'Lugh version');

# Test ggml version
like(Lugh::ggml_version(), qr/ggml/, 'ggml version string');

# Test Context creation
my $ctx = Lugh::Context->new(mem_size => 16 * 1024 * 1024);
isa_ok($ctx, 'Lugh::Context', 'Context created');

# Test memory info
is($ctx->mem_size(), 16 * 1024 * 1024, 'mem_size correct');

# Test 1D tensor creation
my $t1 = Lugh::Tensor->new_f32($ctx, 4);
isa_ok($t1, 'Lugh::Tensor', '1D tensor created');
is($t1->nelements(), 4, 'tensor has 4 elements');
is($t1->n_dims(), 1, 'tensor is 1-dimensional');

# Test set/get values
$t1->set_f32(1.0, 2.0, 3.0, 4.0);
my @vals = $t1->get_f32();
is_deeply(\@vals, [1.0, 2.0, 3.0, 4.0], 'get_f32 returns correct values');

# Test 2D tensor
my $t2 = Lugh::Tensor->new_f32($ctx, 3, 2);
is($t2->nelements(), 6, '2D tensor has 6 elements');
is($t2->n_dims(), 2, '2D tensor has 2 dimensions');
my @shape = $t2->shape();
is_deeply(\@shape, [3, 2], 'shape is [3, 2]');

# Test tensor addition
my $a = Lugh::Tensor->new_f32($ctx, 4);
my $b = Lugh::Tensor->new_f32($ctx, 4);
$a->set_f32(1.0, 2.0, 3.0, 4.0);
$b->set_f32(5.0, 6.0, 7.0, 8.0);

my $c = Lugh::Ops::add($ctx, $a, $b);
isa_ok($c, 'Lugh::Tensor', 'add returns Tensor');

# Build and execute graph
my $graph = Lugh::Graph->new($ctx);
isa_ok($graph, 'Lugh::Graph', 'Graph created');
$graph->build_forward($c);
$graph->compute($ctx, 4);

# Check result
my @result = $c->get_f32();
is_deeply(\@result, [6.0, 8.0, 10.0, 12.0], 'add computed correctly');
