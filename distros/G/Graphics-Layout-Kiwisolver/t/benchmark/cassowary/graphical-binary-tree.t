#!/usr/bin/env perl

use Test::Most tests => 1;

use strict;
use warnings;
use Graphics::Layout::Kiwisolver;

package Node {
	use Mu;
	use Graphics::Layout::Kiwisolver::Variable;
	has [qw(x y)] => (
		is => 'ro',
		default => sub() {
			Graphics::Layout::Kiwisolver::Variable->new;
		}
	);

	has [ qw(left right) ] => ( is => 'rw' );
}

package SolverWithCount {
	use Mu;
	use MooX::InsideOut;
	use MooX::HandlesVia;
	extends qw(Graphics::Layout::Kiwisolver::Solver);
	use Data::Perl qw/counter/;

	ro _count => (
		default => sub { counter(0) },
		handles_via => 'Counter',
		handles => {
			_increment_count => 'inc',
		}
	);
	sub count { my $self = shift; ${ $self->_count } }

	after addConstraint => sub {
		my $self = shift;
		$self->_increment_count;
	}
}

sub tree {
	my ($solver, $depth, $context) = @_;
	my $node = Node->new;

	$solver->addConstraint( $node->x >= $context->{inset} );
	$solver->addConstraint( $node->x <= $context->{width} - $context->{inset} );

	$solver->addConstraint( $node->y >= $context->{inset} );
	$solver->addConstraint( $node->y <= $context->{height} - $context->{inset} );

	if( $depth > 1 ) {
		$node->left( tree( $solver, $depth - 1, $context ) );
		$node->right( tree( $solver, $depth - 1 , $context ) );

		# node x value should be halfway between children's x values
		$solver->addConstraint( $node->x == ($node->left->x + $node->right->x) / 2 );

		# each child needs to be at the same y value
		$solver->addConstraint( $node->left->y == $node->right->y );

		# at least 10 pixels below node's y value
		$solver->addConstraint( $node->left->y >= $node->y + $context->{spacing} );
		$solver->addConstraint( $node->right->y >= $node->y + $context->{spacing} );
	}

	return $node;
}

sub depth_overlap {
	my ($solver, $root, $sep) = @_;
	my @q = ($root);
	while(@q) {
		@q = grep { defined } map { ( $_->left, $_->right ) } @q;
		for my $n (1..@q-1) {
			$solver->addConstraint( $q[$n-1]->x <= $q[$n]->x - $sep );
		}
	}
}

subtest "Test" => sub {
	my $solver = SolverWithCount->new;

	my $context = {
		width => 600,
		height => 150,
		inset => 10,
		spacing => Graphics::Layout::Kiwisolver::Variable->new,
	};

	my $levels = 7;
	my $sep = Graphics::Layout::Kiwisolver::Variable->new;

	$solver->addConstraint( $sep >= 4+1 );
	$solver->addConstraint( $context->{spacing} >= 20 );

	my $count_before = $solver->count;
	my $root = tree($solver, $levels, $context );
	my $count_after = $solver->count;

	depth_overlap($solver, $root, $sep);

	$solver->addEditVariable($root->x, Graphics::Layout::Kiwisolver::Strength::STRONG );
	$solver->addEditVariable($root->y, Graphics::Layout::Kiwisolver::Strength::STRONG );
	$solver->suggestValue( $root->x, $context->{width}  / 2 );
	$solver->suggestValue( $root->y, 10 );

	is $count_after - $count_before, 4 * (2**$levels-1 + 2**($levels-1)-1),
		"expected number of constraints for tree of depth $levels";

	$solver->updateVariables;
	#$solver->dump;

	my $svg = SVG->new;
	$svg->rectangle(
		x => 0, y => 0,
		width => $context->{width}, height => $context->{height},
		style => {
			stroke => 'black',
			'stroke-width' => 1,
			fill => 'none',
		},
	);
	draw($svg, $root);
	use Path::Tiny;
	my $output_path = path('_output')->child(__FILE__ . '.svg');
	$output_path->parent->mkpath;
	$output_path->spew_utf8($svg->xmlify);
};

use SVG;
sub draw {
	my ($svg, $root) = @_;
	my $r_sz = 4;
	$svg->rectangle(
		x => $root->x->value - $r_sz/2,
		y => $root->y->value - $r_sz/2,
		width => $r_sz,
		height => $r_sz,
	);
	for my $child ($root->left, $root->right) {
		next unless $child;
		$svg->line(
			x1 => $root->x->value,
			y1 => $root->y->value,
			x2 => $child->x->value,
			y2 => $child->y->value,
			style => {
				stroke => 'rgb(255,0,0)',
				'stroke-width' => 1,
			},
		);
		draw($svg, $child);
	}
}

done_testing;
