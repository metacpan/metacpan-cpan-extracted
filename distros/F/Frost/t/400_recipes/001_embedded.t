#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 123;
#use Test::More 'no_plan';

use Frost::Asylum;

#   +-----+    +-----+
#   | Foo |--->| Foo |
#   +-----+    +-----+
#
{
	package Foo;

	use Frost;

	has 'num'	=> (is => 'rw', isa => 'Int');
	has 'foo'	=> (is => 'rw', isa => 'Foo');

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

#   +------------+    +-----+
#   | Foo::Array |-+->| Foo |
#   +------------+ |  +-----+
#                  |
#                  |  +-----+
#                  +->| Foo |
#                  |  +-----+
#                  |
#                  |  +-----+
#                  +->| Foo |
#                     +-----+
#
{
	package Foo::Array;

	use Frost;

	has 'foos' =>
	(
		is			=> 'rw',
		isa		=> 'ArrayRef[Foo]',
		default	=> sub { [] },
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

#   +------------+    +-----+
#   | Foo::Hash  |-+->| Foo |
#   +------------+ |  +-----+
#                  |
#                  |  +-----+
#                  +->| Foo |
#                  |  +-----+
#                  |
#                  |  +-----+
#                  +->| Foo |
#                     +-----+
#
{
	package Foo::Hash;
	use Frost;

	has 'foos' =>
	(
		is			=> 'rw',
		isa		=> 'HashRef[Foo]',
		default	=> sub { {} },
	);

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag '### Create Foo ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo1, $foo2, $foo3 );

	lives_ok
	{
		$foo1	= Foo->new ( asylum => $ASYL, id => 'FOO_1', num => 1 );
		$foo2	= Foo->new ( asylum => $ASYL, id => 'FOO_2', num => 2 );
		$foo3	= Foo->new ( asylum => $ASYL, id => 'FOO_3', num => 3 );
	}	'Foos constructed';

	is		$foo1->_status,	STATUS_MISSING,	'got the right _status foo 1';
	is		$foo2->_status,	STATUS_MISSING,	'got the right _status foo 2';
	is		$foo3->_status,	STATUS_MISSING,	'got the right _status foo 3';

	is		$foo1->_dirty,					true,		'got the right _dirty foo 1';
	is		$foo2->_dirty,					true,		'got the right _dirty foo 1';
	is		$foo3->_dirty,					true,		'got the right _dirty foo 1';

	lives_ok	{ $foo1->foo ( $foo2 ); }			'set foo1 -> foo2';
	lives_ok	{ $foo2->foo ( $foo3 ); }			'set foo2 -> foo3';

	is		$foo1->_status,				STATUS_MISSING,	'got the right _status level 1';
	is		$foo1->foo->_status,			STATUS_EXISTS,		'got the right _status level 2';		#	new Locum...
	is		$foo1->foo->foo->_status,	STATUS_EXISTS,		'got the right _status level 3';		#	new Locum...

	is		$foo1->_dirty,					true,		'got the right _dirty level 1';
	is		$foo1->foo->_dirty,			true,		'got the right _dirty level 2';
	is		$foo1->foo->foo->_dirty,	false,	'got the right _dirty level 3';		#	has been saved behind your back...

	is		$foo1->num,						1,			'got the right num level 1';
	is		$foo1->foo->num,				2,			'got the right num level 2';
	is		$foo1->foo->foo->num,		3,			'got the right num level 3';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load Foo ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo1, $foo2, $foo3, $foo3_A );

	lives_ok		{ $foo1	= Foo->new ( asylum => $ASYL, id => 'FOO_1' );		}	'load foo1';

	is		$foo1->num,					1,				'got the right num level 1';
	is		$foo1->foo->num,			2,				'got the right num level 2';
	is		$foo1->foo->foo->num,	3,				'got the right num level 3';

	is		$foo1->_status,				STATUS_EXISTS,		'got the right _status level 1';
	is		$foo1->foo->_status,			STATUS_EXISTS,		'got the right _status level 2';
	is		$foo1->foo->foo->_status,	STATUS_EXISTS,		'got the right _status level 3';

	is		$foo1->id,					'FOO_1',		'got the right id foo1';
	is		$foo1->num,					1,				'got the right num foo1';
	isnt	$foo1->_dirty,				true,			'foo1 is clean';

	$foo2	= $foo1->foo;

	is		$foo2->id,					'FOO_2',		'got the right id foo2';
	is		$foo2->num,					2,				'got the right num foo2';
	isnt	$foo2->_dirty,				true,			'foo2 is clean';

	$foo3	= $foo2->foo;

	is		$foo3->id,					'FOO_3',		'got the right id foo3';
	is		$foo3->num,					3,				'got the right num foo3';
	isnt	$foo3->_dirty,				true,			'foo3 is clean';

	lives_ok		{ $foo3_A	= Foo->new ( asylum => $ASYL, id => 'FOO_3' );		}			'load foo3 again as foo3_A';

	is		$foo3_A->id,				'FOO_3',		'got the right id  foo3_A';
	is		$foo3_A->num,				3,				'got the right num foo3_A';
	isnt	$foo3_A->_dirty,			true,			'foo3_A is clean';

	isnt	$foo3_A,						$foo3,		'instances foo3_A != foo3';		#	!!!
#	because:
#
	isa_ok	( $foo3_A,	'Foo',						'foo3_A'	);
	isa_ok	( $foo3_A,	'Frost::Locum',	'foo3_A'	);
	isa_ok	( $foo3_A,	'Moose::Object'		,	'foo3_A'	);

	isa_ok	( $foo3,		'Foo'						,	'foo3'	);
	isa_ok	( $foo3,		'Frost::Locum',	'foo3'	);
	isa_ok	( $foo3,		'Moose::Object'		,	'foo3'	);

	lives_ok	{ $ASYL->remove;	}	'Asylum removed';
}

diag '### Create Foo::Array ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo, $foo1, $foo2, $foo3 );

	lives_ok
	{
		$foo	= Foo::Array->new ( asylum => $ASYL, id => 'FOO_ARRAY_1' );
	}	'Foo::Array constructed';

	is		$foo->_dirty,				true,			'foo is  _dirty';

	lives_ok
	{
		$foo1	= Foo->new ( asylum => $ASYL, id => 'FOO_101', num => 101 );
		$foo2	= Foo->new ( asylum => $ASYL, id => 'FOO_102', num => 102 );
		$foo3	= Foo->new ( asylum => $ASYL, id => 'FOO_103', num => 103 );
	}	'Foos constructed';

	lives_ok	{ $foo->foos ( [ $foo1, $foo2, $foo3 ] ) }	'set foo -> [ foo1, foo2, foo3 ]';

	is		$foo->foos->[0]->num,		101,		'got the right num child 0';
	is		$foo->foos->[1]->num,		102,		'got the right num child 1';
	is		$foo->foos->[2]->num,		103,		'got the right num child 2';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load Foo::Array ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo, $foo1, $foo2, $foo3, $foo3_A );

	lives_ok		{ $foo	= Foo::Array->new ( asylum => $ASYL, id => 'FOO_ARRAY_1' );		}	'load foo-array';

	isnt	$foo->_dirty,		true,					'foo is  clean';

	$foo1	= $foo->foos->[0];

	is		$foo1->id,			'FOO_101',			'got the right id  child 0';
	is		$foo1->num,			101,					'got the right num child 0';
	isnt	$foo1->_dirty,		true,					'foo1 is clean';

	$foo2	= $foo->foos->[1];

	is		$foo2->id,			'FOO_102',			'got the right id  child 1';
	is		$foo2->num,			102,					'got the right num child 1';
	isnt	$foo2->_dirty,		true,					'foo2 is clean';

	$foo3	= $foo->foos->[2];

	is		$foo3->id,			'FOO_103',			'got the right id  child 2';
	is		$foo3->num,			103,					'got the right num child 2';
	isnt	$foo3->_dirty,		true,					'foo3 is clean';

	lives_ok		{ $foo3_A	= Foo->new ( asylum => $ASYL, id => 'FOO_103' );		}			'load foo3 again as foo3_A';

	is		$foo3_A->id,			'FOO_103',		'got the right id  foo3_A';
	is		$foo3_A->num,			103,				'got the right num foo3_A';
	isnt	$foo3_A->_dirty,		true,				'foo3_A is clean';

	isnt	$foo3_A,						$foo3,		'instances foo3_A != foo3';		#	!!!
#	because:
#
	isa_ok	( $foo3_A,	'Foo',						'foo3_A'	);
	isa_ok	( $foo3_A,	'Frost::Locum',	'foo3_A'	);
	isa_ok	( $foo3_A,	'Moose::Object'		,	'foo3_A'	);

	isa_ok	( $foo3,		'Foo'						,	'foo3'	);
	isa_ok	( $foo3,		'Frost::Locum',	'foo3'	);
	isa_ok	( $foo3,		'Moose::Object'		,	'foo3'	);

	lives_ok	{ $ASYL->remove;	}	'Asylum removed';
}

diag '### Create Foo::Hash ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo, $foo1, $foo2, $foo3 );

	lives_ok
	{
		$foo	= Foo::Hash->new ( asylum => $ASYL, id => 'FOO_HASH_1' );
	}	'Foo::Hash constructed';

	is		$foo->_dirty,				true,			'foo is  _dirty';

	lives_ok
	{
		$foo1	= Foo->new ( asylum => $ASYL, id => 'FOO_201', num => 201 );
		$foo2	= Foo->new ( asylum => $ASYL, id => 'FOO_202', num => 202 );
		$foo3	= Foo->new ( asylum => $ASYL, id => 'FOO_203', num => 203 );
	}	'Foos constructed';

	is		$foo->_dirty,				true,			'foo  is dirty';
	is		$foo1->_dirty,				true,			'foo1 is dirty';
	is		$foo2->_dirty,				true,			'foo2 is dirty';
	is		$foo3->_dirty,				true,			'foo3 is dirty';

	lives_ok	{ $foo->foos ( { 'H_1' => $foo1, 'H_2' => $foo2, 'H_3' => $foo3 } ) }	'set foo -> { foo1, foo2, foo3 }';

	is		$foo->foos->{'H_1'}->num,		201,		'got the right num hash 1';
	is		$foo->foos->{'H_2'}->num,		202,		'got the right num hash 2';
	is		$foo->foos->{'H_3'}->num,		203,		'got the right num hash 3';

	is		$foo->_dirty,				true,			'foo  is dirty';
	isnt	$foo1->_dirty,				true,			'foo1 is clean';
	isnt	$foo2->_dirty,				true,			'foo2 is clean';
	isnt	$foo3->_dirty,				true,			'foo3 is clean';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load Foo::Hash ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum opened';

	my ( $foo, $foo1, $foo2, $foo3, $foo3_A );

	lives_ok		{ $foo	= Foo::Hash->new ( asylum => $ASYL, id => 'FOO_HASH_1' );		}	'load foo-hash';

	isnt	$foo->_dirty,				true,			'foo  is clean';

	$foo1	= $foo->foos->{'H_1'};

	is		$foo1->id,			'FOO_201',			'got the right id  hash 1';
	is		$foo1->num,			201,					'got the right num hash 1';
	isnt	$foo1->_dirty,		true,					'foo1 is clean';

	$foo2	= $foo->foos->{'H_2'};

	is		$foo2->id,			'FOO_202',			'got the right id  hash 2';
	is		$foo2->num,			202,					'got the right num hash 2';
	isnt	$foo2->_dirty,		true,					'foo2 is clean';

	$foo3	= $foo->foos->{'H_3'};

	is		$foo3->id,			'FOO_203',			'got the right id  hash 3';
	is		$foo3->num,			203,					'got the right num hash 3';
	isnt	$foo3->_dirty,		true,					'foo3 is clean';

	lives_ok		{ $foo3_A	= Foo->new ( asylum => $ASYL, id => 'FOO_203' );		}			'load foo3 again as foo3_A';

	is		$foo3_A->id,			'FOO_203',			'got the right id  foo3_A';
	is		$foo3_A->num,			203,					'got the right num foo3_A';
	isnt	$foo3_A->_dirty,		true,					'foo3_A is clean';

	isnt	$foo3_A,						$foo3,		'instances foo3_A != foo3';		#	!!!
#	because:
#
	isa_ok	( $foo3_A,	'Foo',						'foo3_A'	);
	isa_ok	( $foo3_A,	'Frost::Locum',	'foo3_A'	);
	isa_ok	( $foo3_A,	'Moose::Object'		,	'foo3_A'	);

	isa_ok	( $foo3,		'Foo'						,	'foo3'	);
	isa_ok	( $foo3,		'Frost::Locum',	'foo3'	);
	isa_ok	( $foo3,		'Moose::Object'		,	'foo3'	);

	lives_ok	{ $ASYL->remove;	}	'Asylum removed';
}
