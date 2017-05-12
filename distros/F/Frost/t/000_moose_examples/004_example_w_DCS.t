#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

BEGIN {
	eval "use Declare::Constraints::Simple;";
	plan skip_all => "Declare::Constraints::Simple is required for this test" if $@;
	plan tests => 28;
#	plan 'no_plan';
}

use Frost::Asylum;

#	from Moose-0.87/t/200_examples/004_example_w_DCS.t

{
	package Foo;
#	use Moose;
	use Frost;
	use Moose::Util::TypeConstraints;
	use Declare::Constraints::Simple -All;

	# define your own type ...
	type( 'HashOfArrayOfObjects',
		{
		where => IsHashRef(
			-keys   => HasLength,
			-values => IsArrayRef(IsObject)
		)
	} );

	has 'bar' => (
		is  => 'rw',
		isa => 'HashOfArrayOfObjects',
	);

	# inline the constraints as anon-subtypes
	has 'baz' => (
		is  => 'rw',
		isa => subtype( { as => 'ArrayRef', where => IsArrayRef(IsInt) } ),
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package Bar;
#	use Moose;
	use Frost;

	has 'barbar' => (
		is  => 'rw',
		isa => 'Str',
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

#my $hash_of_arrays_of_objs = {
#	foo1 => [ Bar->new ],
#	foo2 => [ Bar->new, Bar->new ],
#};

my $array_of_ints = [ 1 .. 10 ];

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $hash_of_arrays_of_objs = {
	   foo1 => [ Bar->new ( asylum => $ASYL, id => 1000, barbar => 'BB1000' ) ],
	   foo2 => [ Bar->new ( asylum => $ASYL, id => 2000, barbar => 'BB2000' ), Bar->new  ( asylum => $ASYL, id => 2020, barbar => 'BB2020' ) ],
	};

	#	ONLY FOR TESTING:
	#	Load'em again to get rid of _state => 'missing'
	#
	$hash_of_arrays_of_objs = {
	   foo1 => [ Bar->new ( asylum => $ASYL, id => 1000, barbar => 'IGNORE1000' ) ],
	   foo2 => [ Bar->new ( asylum => $ASYL, id => 2000, barbar => 'IGNORE2000' ), Bar->new  ( asylum => $ASYL, id => 2020, barbar => 'IGNORE2020' ) ],
	};

	is	$hash_of_arrays_of_objs->{foo1}->[0]->barbar, 'BB1000', '... got barbar 10 correctly';
	is	$hash_of_arrays_of_objs->{foo2}->[0]->barbar, 'BB2000', '... got barbar 20 correctly';
	is	$hash_of_arrays_of_objs->{foo2}->[1]->barbar, 'BB2020', '... got barbar 22 correctly';

	my $foo;
	lives_ok {
		$foo = Foo->new(
		asylum => $ASYL, id => 3000,
		'bar' => $hash_of_arrays_of_objs,
		'baz' => $array_of_ints,
		);
	} '... construction succeeded';
	isa_ok($foo, 'Foo', 'foo');

	is_deeply($foo->bar, $hash_of_arrays_of_objs, '... got our value correctly');
	is_deeply($foo->baz, $array_of_ints, '... got our value correctly');

	dies_ok {
		$foo->bar([]);
	} '... validation failed correctly';

	dies_ok {
		$foo->bar({ foo => 3 });
	} '... validation failed correctly';

	dies_ok {
		$foo->bar({ foo => [ 1, 2, 3 ] });
	} '... validation failed correctly';

	dies_ok {
		$foo->baz([ "foo" ]);
	} '... validation failed correctly';

	dies_ok {
		$foo->baz({});
	} '... validation failed correctly';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $foo;
	lives_ok {
		$foo = Foo->new(
			asylum => $ASYL, id => 3000,
		);
	} '... reloading succeeded';
	isa_ok($foo, 'Foo', 'foo');

	my $hash_of_arrays_of_objs = {
	   foo1 => [ Bar->new ( asylum => $ASYL, id => 1000, barbar => 'IGNORE1000' ) ],
	   foo2 => [ Bar->new ( asylum => $ASYL, id => 2000, barbar => 'IGNORE2000' ), Bar->new  ( asylum => $ASYL, id => 2020, barbar => 'IGNORE2020' ) ],
	};

	is	$hash_of_arrays_of_objs->{foo1}->[0]->barbar, 'BB1000', '... got barbar 10 correctly';
	is	$hash_of_arrays_of_objs->{foo2}->[0]->barbar, 'BB2000', '... got barbar 20 correctly';
	is	$hash_of_arrays_of_objs->{foo2}->[1]->barbar, 'BB2020', '... got barbar 22 correctly';

	is_deeply($foo->bar, $hash_of_arrays_of_objs, '... loaded our value correctly');

	is_deeply($foo->baz, $array_of_ints, '... loaded our value correctly');

	dies_ok {
		$foo->bar([]);
	} '... validation failed correctly';

	dies_ok {
		$foo->bar({ foo => 3 });
	} '... validation failed correctly';

	dies_ok {
		$foo->bar({ foo => [ 1, 2, 3 ] });
	} '... validation failed correctly';

	dies_ok {
		$foo->baz([ "foo" ]);
	} '... validation failed correctly';

	dies_ok {
		$foo->baz({});
	} '... validation failed correctly';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
