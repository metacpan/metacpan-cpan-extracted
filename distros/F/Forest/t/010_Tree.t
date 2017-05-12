#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 89;
use Test::Exception;

BEGIN {
    use_ok('Forest::Tree');
};

my $t = Forest::Tree->new();
isa_ok($t, 'Forest::Tree');

ok($t->is_root, '... this is the tree root');
ok($t->is_leaf, '... this is the leaf');

ok(!defined $t->parent, '... no parent');
ok(!$t->has_parent, '... no parent');
ok(!defined $t->node, '... no node value');
is_deeply($t->children, [], '... no children');
is($t->depth, -1, '... the root has a depth of -1');
is($t->height, 0, '... the root has a height of 0');
is($t->size,   1, '... the root has a size of 1');

my $child_1 = Forest::Tree->new(node => '1.0');
isa_ok($child_1, 'Forest::Tree');

ok(!defined $child_1->parent, '... no parent');
ok(!$child_1->has_parent, '... no parent');
ok($child_1->is_leaf, '... this is a leaf');
ok($child_1->is_root, '... this is a root');
is($child_1->node, '1.0', '... got the right node value');
is($child_1->depth, -1, '... the child has a depth of -1');
is_deeply($child_1->children, [], '... no children');

$t->add_child($child_1);

ok(!$t->is_leaf, '... this is no longer leaf');
is_deeply($t->children, [ $child_1 ], '... 1 child');
is($t->depth, -1, '... the root still has a depth of -1');
is($t->height, 1, '... the root now has a height of 1');
is($t->size,   2, '... the root now has a size of 2');
is($t->get_child_at(0), $child_1, '... got the right child');

ok(!$child_1->is_root, '... this is no longer a root');
ok($child_1->is_leaf, '... but this is still a leaf');
ok(defined $child_1->parent, '... has parent now');
ok($child_1->has_parent, '... has parent now');
isa_ok($child_1->parent, 'Forest::Tree');
is($child_1->parent, $t, '... its parent is tree');
is($child_1->depth, 0, '... the child now has a depth of 0');
is_deeply($child_1->siblings, [], '... There are no siblings');

my $child_1_1 = Forest::Tree->new(node => '1.1');
isa_ok($child_1_1, 'Forest::Tree');

ok(!defined $child_1_1->parent, '... no parent');
ok(!$child_1_1->has_parent, '... no parent');
ok($child_1_1->is_leaf, '... this is a leaf');
ok($child_1_1->is_root, '... this is a root');
is($child_1_1->node, '1.1', '... got the right node value');
is($child_1_1->depth, -1, '... the child has a depth of -1');
is_deeply($child_1_1->children, [], '... no children');

$t->get_child_at(0)->add_child($child_1_1);

is_deeply($child_1->children, [ $child_1_1 ], '... one child');

ok(!$child_1->is_leaf, '... this is no longer a leaf');
is($child_1->depth, 0, '... the child still has a depth of 0');

ok(!$child_1_1->is_root, '... this is no longer a root');
ok($child_1_1->is_leaf, '... but this is still a leaf');
ok(defined $child_1_1->parent, '... has parent now');
ok($child_1_1->has_parent, '... has parent now');
isa_ok($child_1_1->parent, 'Forest::Tree');
is($child_1_1->parent, $child_1, '... its parent is tree');
is($child_1_1->depth, 1, '... the child now has a depth of 1');
is($t->height, 2, '... the root now has a height of 2');
is($t->size,   3, '... the root now has a size of 3');

my $child_2 = Forest::Tree->new(node => '2.0');
isa_ok($child_2, 'Forest::Tree');

my $child_3 = Forest::Tree->new(node => '3.0');
isa_ok($child_3, 'Forest::Tree');

my $child_4 = Forest::Tree->new(node => '4.0');
isa_ok($child_4, 'Forest::Tree');

$child_1->add_sibling($child_4);

is_deeply($child_1->siblings, [ $child_4 ], '... There are no siblings');

is_deeply($t->children, [ $child_1, $child_4 ], '... 2 children');

ok(!$child_4->is_root, '... this is no longer a root');
ok($child_4->is_leaf, '... but this is still a leaf');
is($child_4->parent, $t, '... its parent is tree');
is($child_4->depth, 0, '... the child now has a depth of 1');

$t->insert_child_at(1, $child_2);

is_deeply($t->children, [ $child_1, $child_2, $child_4 ], '... 3 children');

ok(!$child_2->is_root, '... this is no longer a root');
ok($child_2->is_leaf, '... but this is still a leaf');
is($child_2->parent, $t, '... its parent is tree');
is($child_2->depth, 0, '... the child now has a depth of 1');

$child_2->insert_sibling_at(2, $child_3);

is_deeply($t->children, [ $child_1, $child_2, $child_3, $child_4 ], '... 4 children');

ok(!$child_3->is_root, '... this is no longer a root');
ok($child_3->is_leaf, '... but this is still a leaf');
is($child_3->parent, $t, '... its parent is tree');
is($child_3->depth, 0, '... the child now has a depth of 1');
is($t->height, 2, '... the root now has a height of 2');
is($t->size,   6, '... the root now has a size of 6');

ok($t->remove_child_at(0), '... removing child 1');
is($t->height, 1, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 4');

# clear them ...
$t->clear_size;
$t->clear_height;

# regenerate ...

ok($t->remove_child_at(0), '... removing child 1');

is($t->height, 1, '... the root now has a height of 1');
is($t->size,   3, '... the root now has a size of 3');



my $child_5 = Forest::Tree->new(node => '5.0');
my $child_6 = Forest::Tree->new(node => '6.0');
my $child_7 = Forest::Tree->new(node => '7.0');

$t->transform( [ 1 ], insert_child_at => 0, $child_5 );

is($t->height, 2, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 3');

is_deeply( $t->locate(1, 0), $child_5, "locate new child" );

$t->transform( [ 1, 0 ], add_child => $child_6 );

is($t->height, 3, '... the root now has a height of 1');
is($t->size,   5, '... the root now has a size of 3');

is( $t->locate(1, 0, 0)->node, '6.0', "correct node" );

$t->transform( [ 1, 0 ], replace => $child_7 );

is($t->height, 2, '... the root now has a height of 1');
is($t->size,   4, '... the root now has a size of 3');

is( $t->locate(1, 0)->node, "7.0", "correct node" );
