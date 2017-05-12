#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More tests => 15;
use Test::More 'no_plan';

our $LEVEL	= 4;		#	min 3
our $CHILD	= 2;		#	min 1

use Frost::Asylum;

#   +------+         +------+
#   | Tree |<---+--->| Tree |...
#   +------+    |    +------+
#               |
#               |    +------+         +------+
#               +--->| Tree |<---+--->| Tree |...
#                    +------+    |    +------+
#                                |
#                                |    +------+
#                                +--->| Tree |...
#                                     +------+
#
{
	package Tree;

	use Frost;
	use Frost::Util;

	has 'node'		=> ( is => 'rw' );

	has 'children' =>
	(
		is				=> 'rw',
		isa			=> 'ArrayRef[Tree]',
		default		=> sub { [] }
	);

	has 'parent'	=>
	(
		is				=> 'rw',
		isa			=> 'Tree',

		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	sub add_child
	{
		my ( $self, $child )	= @_;

		$child->parent ( $self );

		my @a	= @{ $self->children };

		push @a, $child;

		$self->children ( \@a );		#	trigger type constraint check...
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag '### Create Tree ###';

no warnings "recursion";

our $ID		= 1;

our $CONTROL	= {};

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	sub build_tree
	{
		my ( $node, $level )	= @_;

		$level++;

		return $node		if $level > $LEVEL;

		foreach my $child ( 1 .. $CHILD )
		{
			$ID++;

			my $new_node	= Tree->new ( asylum => $ASYL, id => $ID, node => "$level\.$child\.$ID" );

			$CONTROL->{$new_node->id}	= $new_node->node;

			my $leaf			= build_tree ( $new_node, $level );

			$node->add_child ( $leaf );
		}

		$node;
	}

	my $root	= Tree->new ( asylum => $ASYL, id => $ID, node => "0.0.1" );

	$CONTROL->{$root->id}	= $root->node;

	build_tree ( $root, 0 );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load Tree ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $c;

	my $tree				= Tree->new ( asylum => $ASYL, id => 1 );
	$c						= $CONTROL->{$tree->id};
	is		(	$tree->node,			$c,		"got node $c for " . $tree->id );

	my $node				= $tree->children->[0];
	$c						= $CONTROL->{$node->id};
	is		(	$node->node,			$c,		"got node $c for " . $node->id );

	my $node_child		= $node->children->[0];
	$c						= $CONTROL->{$node_child->id};
	is		(	$node_child->node,	$c,		"got node $c for " . $node_child->id );

	my $node_parent	= $node_child->parent;

	$c						= $CONTROL->{$node_parent->id};

	is		(	$node_parent->node,	$c,		"got node $c for " . $node_parent->id );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load Tree last leaf ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $c;

	my $node				= Tree->new ( asylum => $ASYL, id => $ID );
	$c						= $CONTROL->{$node->id};
	is		(	$node->node,			$c,		"got node $c for " . $node->id );

	my $node_child		= $node->children->[0];

	ok	(	!	$node_child,						'no children' );

	my $node_parent	= $node->parent;
	$c						= $CONTROL->{$node_parent->id};
	is		(	$node_parent->node,	$c,		"got node $c for " . $node_parent->id );

	my $node_parent2	= $node_parent->parent;
	$c						= $CONTROL->{$node_parent2->id};
	is		(	$node_parent2->node,	$c,		"got node $c for " . $node_parent2->id );

	my $find_root	= $node_parent;

	#IS_DEBUG and DEBUG "Find root...";

	lives_ok
	{
		while ( $find_root->node ne "0.0.1" )
		{
			last		if $find_root->node eq "0.0.1";

			$find_root	= $find_root->parent;

			( defined $find_root )						or die 'UNDEFINED';

			#IS_DEBUG and DEBUG "IN: $find_root";
		}
	}
	'find root';

	is 		( $find_root->id,		1,				'got the right id' );
	is 		( $find_root->node,	"0.0.1",		'got the right node' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
