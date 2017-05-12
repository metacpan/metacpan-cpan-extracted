#!/usr/bin/perl -w

use strict;
use warnings;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More 'no_plan';
use Test::Exception;
use Test::Differences;

$| = 1;

use Frost::Asylum;
use Frost::Util;

$Frost::Util::UUID_CLEAR	= 1;		#	delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing

$Data::Dumper::Deparse	= true;

# =begin testing SETUP
{
	package Point;
#	use Moose;
	use Frost;

	has id	=> ( auto_id	=> 1 );

	has 'x' => (isa => 'Int', is => 'rw', required => 1);
	has 'y' => (isa => 'Int', is => 'rw', required => 1);

	sub clear {
		my $self = shift;
		$self->x(0);
		$self->y(0);
	}

	no Frost;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Point3D;
	use Moose;

	extends 'Point';

	has 'z' => (isa => 'Int', is => 'rw', required => 1);

	after 'clear' => sub {
		my $self = shift;
		$self->z(0);
	};

	no Moose;
	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package main;

	use vars qw($CANVAS);

	$CANVAS = Frost::Asylum->new ( data_root	=> $TMP_PATH );

	# hash or hashrefs are ok for the constructor
	my $point1 = Point->new(x => 5, y => 7, asylum => $CANVAS );
	my $point2 = Point->new({x => 5, y => 7, asylum => $CANVAS });

	my $point3d = Point3D->new(x => 5, y => 42, z => -5, asylum => $CANVAS );

	$CANVAS->close;	#	and save
}

$CANVAS->clear;	#	delete all above points

my $POINT;

# =begin testing
{
	my $point = Point->new( x => 1, y => 2, asylum => $CANVAS );
	isa_ok( $point, 'Point' );
	isa_ok( $point, 'Moose::Object' );
	isa_ok( $point, 'Frost::Locum' );

	is( $point->x, 1, '... got the right value for x' );
	is( $point->y, 2, '... got the right value for y' );

	$point->y(10);
	is( $point->y, 10, '... got the right (changed) value for y' );

	$POINT	= { id => $point->id, x => $point->x, y => $point->y };

	$CANVAS->close;
}

{
	my $point	= Point->new ( id => $POINT->{id}, asylum => $CANVAS );
	isa_ok( $point, 'Point' );
	isa_ok( $point, 'Moose::Object' );
	isa_ok( $point, 'Frost::Locum' );

	is( $point->x, $POINT->{x}, '... got the right value for x (reloaded)' );
	is( $point->y, $POINT->{y}, '... got the right (changed) value for y (reloaded)' );

	dies_ok {
		$point->y('Foo');
	}
	'... cannot assign a non-Int to y';

	dies_ok {
		Point->new( asylum => $CANVAS );
	}
	'... must provide required attributes to new';

	$point->clear();

	is( $point->x, 0, '... got the right (cleared) value for x' );
	is( $point->y, 0, '... got the right (cleared) value for y' );

	$CANVAS->close;
}

# check the type constraints on the constructor

lives_ok {
	Point->new( x => 0, y => 0, asylum => $CANVAS );
}
'... can assign a 0 to x and y';

dies_ok {
	Point->new( x => 10, y => 'Foo', asylum => $CANVAS	);
}
'... cannot assign a non-Int to y';

dies_ok {
	Point->new( x => 'Foo', y => 10, asylum => $CANVAS );
}
'... cannot assign a non-Int to x';

# Point3D
{
	my $point3d = Point3D->new( { x => 10, y => 15, z => 3, asylum => $CANVAS} );
	isa_ok( $point3d, 'Point3D' );
	isa_ok( $point3d, 'Point' );
	isa_ok( $point3d, 'Moose::Object' );
	isa_ok( $point3d, 'Frost::Locum' );

	is( $point3d->x,	10, '... got the right value for x' );
	is( $point3d->y,	15, '... got the right value for y' );
#	is( $point3d->{'z'}, 3,	'... got the right value for z' );		#	verboten, always use accessors !
	is( $point3d->z, 3,	'... got the right value for z' );		#	verboten, always use accessors !

	$POINT	= { id => $point3d->id, x => $point3d->x, y => $point3d->y, z => $point3d->z };

	$CANVAS->close;
}

{
	my $point3d = Point3D->new( { id => $POINT->{id}, asylum => $CANVAS } );
	isa_ok( $point3d, 'Point3D' );
	isa_ok( $point3d, 'Point' );
	isa_ok( $point3d, 'Moose::Object' );
	isa_ok( $point3d, 'Frost::Locum' );

	is( $point3d->x,	10, '... got the right value for x' );
	is( $point3d->y,	15, '... got the right value for y' );
#	is( $point3d->{'z'}, 3,	'... got the right value for z' );		#	verboten, always use accessors !
	is( $point3d->z, 3,	'... got the right value for z' );		#	verboten, always use accessors !

	$point3d->clear();

	is( $point3d->x, 0, '... got the right (cleared) value for x' );
	is( $point3d->y, 0, '... got the right (cleared) value for y' );
	is( $point3d->z, 0, '... got the right (cleared) value for z' );

	$CANVAS->close;
}

dies_ok {
	Point3D->new( x => 10, y => 'Foo', z => 3, asylum => $CANVAS );
}
'... cannot assign a non-Int to y';

dies_ok {
	Point3D->new( x => 'Foo', y => 10, z => 3, asylum => $CANVAS );
}
'... cannot assign a non-Int to x';

dies_ok {
	Point3D->new( x => 0, y => 10, z => 'Bar', asylum => $CANVAS );
}
'... cannot assign a non-Int to z';

dies_ok {
	Point3D->new( x => 10, y => 3, asylum => $CANVAS );
}
'... z is a required attribute for Point3D';

#	DON'T DO THIS AT HOME!
#
#	We are NOT dead - test ist still running -,
#	so if we do not manually remove the failing
#	entry here, Locum->save will fail later,
#	because the object is incomplete -
#	i.e. asylum missing!
#
#	$CANVAS->remove;

# test some class introspection

can_ok( 'Point', 'meta' );
isa_ok( Point->meta, 'Moose::Meta::Class' );

can_ok( 'Point3D', 'meta' );
isa_ok( Point3D->meta, 'Moose::Meta::Class' );

isnt( Point->meta, Point3D->meta,
	'... they are different metaclasses as well' );

# poke at Point

eq_or_diff(
	[ Point->meta->superclasses ],
#	['Moose::Object'],
	['Frost::Locum'],
	'... Point got the automagic base class'
);

#	my @Point_methods = qw(meta x y clear);
my @Point_methods = qw(meta x y clear DESTROY new id);
#	my @Point_attrs = ( 'x', 'y' );
my @Point_attrs = ( 'x', 'y', 'id' );

eq_or_diff(
	[ sort Point->meta->get_method_list() ],
	[ sort @Point_methods ],
	'... we match the method list for Point'
);

eq_or_diff(
	[ sort @Point_attrs ],
	[ sort Point->meta->get_attribute_list() ],
	'... we match the attribute list for Point'
);

foreach my $method (@Point_methods) {
	ok( Point->meta->has_method($method),
		'... Point has the method "' . $method . '"' );
}

foreach my $attr_name (@Point_attrs) {
	ok( Point->meta->has_attribute($attr_name),
		'... Point has the attribute "' . $attr_name . '"' );
	my $attr = Point->meta->get_attribute($attr_name);
	ok( $attr->has_type_constraint,
		'... Attribute ' . $attr_name . ' has a type constraint' );
	isa_ok( $attr->type_constraint, 'Moose::Meta::TypeConstraint' );
	if ( $attr_name eq 'id' )
	{
		is( $attr->type_constraint->name, 'Frost::UniqueStringId',
			'... Attribute ' . $attr_name . ' has a Frost::UniqueStringId type constraint' );
	}
	else
	{
		is( $attr->type_constraint->name, 'Int',
			'... Attribute ' . $attr_name . ' has an Int type constraint' );
	}
}

# poke at Point3D

eq_or_diff(
	[ Point3D->meta->superclasses ],
	['Point'],
	'... Point3D gets the parent given to it'
);

#	my @Point3D_methods	= qw( meta z clear );
my @Point3D_methods = qw(meta z clear DESTROY new );	#	x y id	don't show up here...
my @Point3D_attrs		= ('z');									#	x y id	don't show up here...

eq_or_diff(
	[ sort Point3D->meta->get_method_list() ],
	[ sort @Point3D_methods ],
	'... we match the method list for Point3D'
);

eq_or_diff(
	[ sort Point3D->meta->get_attribute_list() ],
	[ sort @Point3D_attrs ],
	'... we match the attribute list for Point3D'
);

foreach my $method (@Point3D_methods) {
	ok( Point3D->meta->has_method($method),
		'... Point3D has the method "' . $method . '"' );
}

foreach my $attr_name (@Point3D_attrs) {
	ok( Point3D->meta->has_attribute($attr_name),
		'... Point3D has the attribute "' . $attr_name . '"' );
	my $attr = Point3D->meta->get_attribute($attr_name);
	ok( $attr->has_type_constraint,
		'... Attribute ' . $attr_name . ' has a type constraint' );
	isa_ok( $attr->type_constraint, 'Moose::Meta::TypeConstraint' );
	if ( $attr_name eq 'id' )
	{
		is( $attr->type_constraint->name, 'Frost::UniqueStringId',
			'... Attribute ' . $attr_name . ' has a Frost::UniqueStringId type constraint' );
	}
	else
	{
		is( $attr->type_constraint->name, 'Int',
			'... Attribute ' . $attr_name . ' has an Int type constraint' );
	}
}

#DEBUG 'B4 DONE...', Dumper $CANVAS;

diag "DONE";

1;


