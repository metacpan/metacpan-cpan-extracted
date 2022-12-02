#!/usr/bin/env perl

use Test::Most tests => 1;

use strict;
use warnings;
use Graphics::Layout::Kiwisolver;

sub tree {
	my ($solver, $n, $leaves) = @_;
	my $node = Graphics::Layout::Kiwisolver::Variable->new;

	if( $n > 1 ) {
		# The value at each interior node is constrained to be the sum
		# of the values of its children.
		my $left = tree($solver, $n-1, $leaves);
		my $right = tree($solver, $n-1, $leaves);

		$solver->addConstraint($node == $left + $right);
	} else {
		# There is also a weak stay constraint on each leaf.
		$solver->addEditVariable($node, Graphics::Layout::Kiwisolver::Strength::WEAK );
		$solver->suggestValue($node, 1);
		$node->setName("leaf_@{[ scalar @$leaves ]}");
		push @$leaves, $node;
	}

	$node;
}

subtest "Tree benchmark" => sub {
	my $solver = Graphics::Layout::Kiwisolver::Solver->new;
	my $n = 10;
	my $leaves = [];
	my $root = tree($solver, $n, $leaves);
	$root->setName('root');

	$solver->updateVariables;
	is $root->value, 2**($n-1), 'initial solution';

	# We then add a strong edit constraint to the root.
	$solver->addEditVariable($root, Graphics::Layout::Kiwisolver::Strength::STRONG );

	# Change value of root one time.
	my $new_value = 2**$n;
	$solver->suggestValue($root, $new_value);
	$solver->updateVariables;

	note $root;
	is $root->value, $new_value, 'root node has new value';
	note $leaves->[0];
	is $leaves->[0]->value, 1 + $new_value/2, 'first leaf';
	note $leaves->[1];
	is $leaves->[1]->value, 1, 'second leaf';

	pass;
};

done_testing;
