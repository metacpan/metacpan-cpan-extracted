#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 41;

use Frost::Asylum;

=pod

Some examples of triggers and how they can
be used to manage parent-child relationships.

=cut

#	from Moose-0.87/t/200_examples/007_Child_Parent_attr_inherit.t

{
	package Parent;
#	use Moose;
	use Frost;

	has 'last_name' => (
		is	=> 'rw',
		isa	=> 'Str',
		trigger => sub {
			my $self = shift;

			# if the parents last-name changes
			# then so do all the childrens
			foreach my $child ( @{ $self->children } ) {
				$child->last_name( $self->last_name );
			}
		}
	);

	has 'children' =>
		( is => 'rw', isa => 'ArrayRef', default => sub { [] } );

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Child;
#	use Moose;
	use Frost;

	has 'parent' => (
		is	=> 'rw',
		isa	=> 'Parent',
		required => 1,
		trigger  => sub {
			my $self = shift;

			# if the parent is changed,..
			# make sure we update
			$self->last_name( $self->parent->last_name );
		}
	);

	has 'last_name' => (
		is	=> 'rw',
		isa	=> 'Str',
		lazy	=> 1,
		default => sub { (shift)->parent->last_name }
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $parent = Parent->new( last_name => 'Smith', asylum => $ASYL, id => 'P001' );
	isa_ok( $parent, 'Parent', 'parent' );

	is( $parent->last_name, 'Smith',
		'... the parent has the last name we expected' );

	$parent->children( [ map { Child->new( parent => $parent, asylum => $ASYL, id => 'C00' . ( $_ + 1 ) ) } ( 0 .. 3 ) ] );

	foreach my $child ( @{ $parent->children } ) {
		is( $child->last_name, $parent->last_name,
				'... parent and child have the same last name ('
				. $parent->last_name
				. ')' );
	}

	$parent->last_name('Jones');
	is( $parent->last_name, 'Jones', '... the parent has the new last name' );

	foreach my $child ( @{ $parent->children } ) {
		is( $child->last_name, $parent->last_name,
				'... parent and child have the same last name ('
				. $parent->last_name
				. ')' );
	}

	# make a new parent

	my $parent2 = Parent->new( last_name => 'Brown', asylum => $ASYL, id => 'P002' );
	isa_ok( $parent2, 'Parent', 'parent2' );

	# orphan the child

#	my $orphan = pop @{ $parent->children };
#
#	CAVEAT of BDB!
#	We have to put back the popped children to reflect the change:
#
	my @children	= @{ $parent->children };

	my $orphan		= pop @children;

	$parent->children ( [ @children ] );

	# and then the new parent adopts it

	$orphan->parent($parent2);

	foreach my $child ( @{ $parent->children } ) {
		is( $child->last_name, $parent->last_name,
				'... parent and child have the same last name ('
				. $parent->last_name
				. ')' );
	}

	isnt( $orphan->last_name, $parent->last_name,
			'... the orphan child does not have the same last name anymore ('
			. $parent2->last_name
			. ')' );
	is( $orphan->last_name, $parent2->last_name,
			'... parent2 and orphan child have the same last name ('
			. $parent2->last_name
			. ')' );

	# make sure that changes still will not propagate

	$parent->last_name('Miller');
	is( $parent->last_name, 'Miller',
		'... the parent has the new last name (again)' );

	foreach my $child ( @{ $parent->children } ) {
		is( $child->last_name, $parent->last_name,
				'... parent and child have the same last name ('
				. $parent->last_name
				. ')' );
	}

	isnt( $orphan->last_name, $parent->last_name,
		'... the orphan child is not affected by changes in the parent anymore' );
	is( $orphan->last_name, $parent2->last_name,
			'... parent2 and orphan child have the same last name ('
			. $parent2->last_name
			. ')' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my ( $parent, $parent2, $orphan );

	lives_ok {
		$parent = Parent->new( last_name => 'Smith', asylum => $ASYL, id => 'P001' );	#	Smith is ignored!
	} 'Parent (1) and his Children loaded';

	isa_ok( $parent, 'Parent', 'parent' );

	is( $parent->last_name, 'Miller',	'... the parent has the last name we stored' );

	is( @{ $parent->children }, 3,		'... the parent has 3 own children' );

	foreach my $child ( @{ $parent->children } ) {
		is( $child->last_name, $parent->last_name,
				'... parent and child have the same last name ('
				. $parent->last_name
				. ')' );
	}

	lives_ok {
		$orphan = Child->new( asylum => $ASYL, id => 'C004' );
	} 'Orphan and his Parent (2) loaded';

	isa_ok( $orphan, 'Child', 'orphan' );

	$parent2 = $orphan->parent;
	isa_ok( $parent2, 'Parent', 'parent' );

	is( $parent2->last_name, 'Brown',	'... the parent has the last name we stored' );

	is( @{ $parent2->children }, 0,		'... the parent has no own children' );

	isnt( $orphan->last_name, $parent->last_name,
		'... the orphan child was not affected by changes in the parent' );
	is( $orphan->last_name, $parent2->last_name,
			'... parent2 and orphan child have the same last name ('
			. $parent2->last_name
			. ')' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
