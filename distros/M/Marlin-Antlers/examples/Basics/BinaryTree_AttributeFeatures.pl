BEGIN {{{ # Port of Moose::Cookbook::Basics::BinaryTree_AttributeFeatures

package BinaryTree {
	use Marlin::Antlers;
	use Carp 'confess';

	has node => ( is => rw );

	has parent => (
		is        => rw,
		isa       => 'BinaryTree',
		predicate => true,
		weak_ref  => true,
	);

	has [ qw( left right ) ] => (
		is        => rw,
		isa       => 'BinaryTree',
		predicate => true,
		lazy      => true,
		default   => sub ( $self ) { BinaryTree->new( parent => $self ) },
		trigger   => '_set_parent_for_child',
	);

	sub _set_parent_for_child ( $self, $child ) {
		confess "You cannot insert a tree which already has a parent"
			if $child->has_parent;
		$child->parent( $self );
	}
}

}}};

use Test2::V0;
use Data::Dumper;
use B::Deparse;

use Scalar::Util qw( isweak );

my $root = BinaryTree->new(node => 'root');
isa_ok($root, 'BinaryTree');

is($root->node, 'root', '... got the right node value');

ok(!$root->has_left, '... no left node yet');
ok(!$root->has_right, '... no right node yet');

ok(!$root->has_parent, '... no parent for root node');

# make a left node

my $left = $root->left;
isa_ok($left, 'BinaryTree');

ref_is($root->left, $left, '... got the same node (and it is $left)');
ok($root->has_left, '... we have a left node now');

ok($left->has_parent, '... lefts has a parent');
ref_is($left->parent, $root, '... lefts parent is the root');

ok(isweak($left->{parent}), '... parent is a weakened ref');

ok(!$left->has_left, '... $left no left node yet');
ok(!$left->has_right, '... $left no right node yet');

is($left->node, undef, '... left has got no node value');

ok lives { $left->node('left') };

is($left->node, 'left', '... left now has a node value');

# make a right node

ok(!$root->has_right, '... still no right node yet');

is($root->right->node, undef, '... right has got no node value');

ok($root->has_right, '... now we have a right node');

my $right = $root->right;
isa_ok($right, 'BinaryTree');

ok lives { $right->node('right') };

is($right->node, 'right', '... left now has a node value');

ref_is($root->right, $right, '... got the same node (and it is $right)');
ok($root->has_right, '... we have a right node now');

ok($right->has_parent, '... rights has a parent');
ref_is($right->parent, $root, '... rights parent is the root');

ok(isweak($right->{parent}), '... parent is a weakened ref');

# make a left node of the left node

my $left_left = $left->left;
isa_ok($left_left, 'BinaryTree');

ok($left_left->has_parent, '... left does have a parent');

ref_is($left_left->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_left, '... we have a left node now');
ref_is($left->left, $left_left, '... got a left node (and it is $left_left)');

ok(isweak($left_left->{parent}), '... parent is a weakened ref');

# make a right node of the left node

my $left_right = BinaryTree->new;
isa_ok($left_right, 'BinaryTree');

ok lives { $left->right($left_right) };

ok($left_right->has_parent, '... left does have a parent');

ref_is($left_right->parent, $left, '... got a parent node (and it is $left)');
ok($left->has_right, '... we have a left node now');
ref_is($left->right, $left_right, '... got a left node (and it is $left_left)');

ok(isweak($left_right->{parent}), '... parent is a weakened ref');

# and check the error

my $e = dies {
	$left_right->right($left_left);
};
like $e, qr/You cannot insert a tree which already has a parent/;

done_testing;
