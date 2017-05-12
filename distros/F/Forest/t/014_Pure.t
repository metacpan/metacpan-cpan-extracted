#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 52;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree::Pure');
};

my $t = Forest::Tree::Pure->new();
isa_ok($t, 'Forest::Tree::Pure');

ok($t->is_leaf, '... this is the leaf');

ok(!defined $t->node, '... no node value');
is_deeply($t->children, [], '... no children');
is($t->height, 0, '... the root has a height of 0');
is($t->size,   1, '... the root has a size of 1');

my $child_1 = Forest::Tree::Pure->new(node => '1.0');
isa_ok($child_1, 'Forest::Tree::Pure');

ok($child_1->is_leaf, '... this is a leaf');
is($child_1->node, '1.0', '... got the right node value');
is_deeply($child_1->children, [], '... no children');

my $clone = $t->add_child($child_1);

ok($t->is_leaf, '... original unmodified');

ok(!defined $t->node, '... no node value');
is_deeply($t->children, [], '... no children');
is($t->height, 0, '... the root has a height of 0');
is($t->size,   1, '... the root has a size of 1');


ok(!$clone->is_leaf, '... this is no longer leaf');
is_deeply($clone->children, [ $child_1 ], '... 1 child');
is($clone->height, 1, '... the root now has a height of 1');
is($clone->size,   2, '... the root now has a size of 2');
is($clone->get_child_at(0), $child_1, '... got the right child');
ok($child_1->is_leaf, '... child is still a leaf');

my $child_1_1 = Forest::Tree::Pure->new(node => '1.1');
isa_ok($child_1_1, 'Forest::Tree::Pure');

ok($child_1_1->is_leaf, '... this is a leaf');
is($child_1_1->node, '1.1', '... got the right node value');
is_deeply($child_1_1->children, [], '... no children');

#### XXX $t is overwritten here #####
$t = $clone->set_child_at( 0 => $clone->get_child_at(0)->add_child($child_1_1) );

$child_1 = $t->get_child_at(0);

is_deeply($child_1->children, [ $child_1_1 ], '... one child');

ok(!$child_1->is_leaf, '... this is no longer a leaf');

ok($child_1_1->is_leaf, '... but this is still a leaf');
is($t->height, 2, '... the root now has a height of 2');
is($t->size,   3, '... the root now has a size of 3');

my $child_2 = Forest::Tree::Pure->new(node => '2.0');
isa_ok($child_2, 'Forest::Tree::Pure');

my $child_3 = Forest::Tree::Pure->new(node => '3.0');
isa_ok($child_3, 'Forest::Tree::Pure');

my $child_4 = Forest::Tree::Pure->new(node => '4.0');
isa_ok($child_4, 'Forest::Tree::Pure');

$t = $t->add_child($child_4);

is_deeply($t->children, [ $child_1, $child_4 ], '... 2 children');

$t = $t->insert_child_at(1, $child_2);

is_deeply($t->children, [ $child_1, $child_2, $child_4 ], '... 3 children');

$t = $t->insert_child_at(2, $child_3);

is_deeply($t->children, [ $child_1, $child_2, $child_3, $child_4 ], '... 4 children');

is($t->height, 2, '... the root now has a height of 2');
is($t->size,   6, '... the root now has a size of 6');

$t = $t->remove_child_at(0);

is($t->height, 1, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 4');

# clear them ...
$t->clear_size;
$t->clear_height;

# regenerate ...

$t = $t->remove_child_at(0);

is($t->height, 1, '... the root now has a height of 1');
is($t->size,   3, '... the root now has a size of 3');

my $child_5 = Forest::Tree::Pure->new(node => '5.0');
my $child_6 = Forest::Tree::Pure->new(node => '6.0');
my $child_7 = Forest::Tree::Pure->new(node => '7.0');

$t = $t->transform( [ 1 ], insert_child_at => 0, $child_5 );

is($t->height, 2, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 3');

is_deeply( $t->locate(1, 0), $child_5, "locate new child" );

$t = $t->transform( [ 1, 0 ], add_child => $child_6 );

is($t->height, 3, '... the root now has a height of 1');
is($t->size,   5, '... the root now has a size of 3');

is_deeply( $t->locate(1, 0, 0), $child_6, "locate new child" );

$t = $t->transform( [ 1, 0 ], replace => $child_7 );

is($t->height, 2, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 3');

is( $t->locate(1, 0)->node, "7.0", "correct node" );
