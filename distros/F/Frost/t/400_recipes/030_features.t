#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 57;
#use Test::More 'no_plan';

use Frost::Asylum;

#	Feature		Locum	Twilight	Cemetery	Illuminator	Access (default)
#
#	transient	X		-			-			-				r/w	(ro)
#	virtual		-		X			-			-				r/w	(ro)
#	derived		-		X			-			-				ro		(ro)
#	index			-		X			X			X				r/w	(--)
#	(none)		-		X			X			-				r/w	(--)

#	Attr "id"	X		X			X			-				ro		(ro)

#	A transient attribute lives at run-time and is "local":
#	It becomes undef, when the Locum object goes out of scope,
#	and it is not stored.

#	A virtual attribute lives at run-time and is "global":
#	It is still present, when the Locum object goes out of scope,
#	but it is not stored.

#	The definition
#
#		has deri_att => ( derived => 1, isa => 'Str' );
#
#	is a shortcut for:
#
#		has deri_att => ( virtual => 1, isa => 'Str', is => 'ro', lazy_build => 1 );
#
#	which becomes:
#
#		has deri_att => (
#			virtual		=> 1,
#			is				=> 'ro',
#			isa			=> 'Str',
#			lazy			=> 1,							#	lazy_build...
#			builder		=> '_build_deri_att',	#
#			clearer		=> 'clear_deri_att',		#
#			predicate	=> 'has_deri_att',		#
#		);

{
	package Foo;
	use Frost;

#	Inherited from Locum:
#
#	has id		=> ( 						isa => 'Frost::UniqueId',	is	=> 'ro',	required => true		);
#
#	has asylum	=> ( transient => 1,	isa => 'Frost::Asylum',	required => true		);
#	has _status	=> ( transient => 1,	isa => 'Frost::Status',		init_arg => undef,	default => STATUS_MISSING	);
#		transient, because accessed by Locum many times
#		not stored, because only needed at runtime
#
#	has _dirty	=> ( virtual	=> 1,	isa => 'Bool',			init_arg => undef,	default => true				);
#		virtual, because accessed by Asylum/Twilight directly
#		not stored, because only needed at runtime

	has foo_tr_def	=> ( transient	=> 1,	isa => 'Str',	is => 'rw',	default => 'TRANSIENT DEFAULT'	);
	has foo_tr		=> ( transient	=> 1,	isa => 'Str',	is => 'rw',	);
	has foo_vi_def	=> ( virtual	=> 1,	isa => 'Str',	is => 'rw',	default => 'VIRTUAL DEFAULT'	);
	has foo_vi		=> ( virtual	=> 1,	isa => 'Str',	is => 'rw',	);
	has foo_de		=> ( derived	=> 1,	isa => 'Str',					);
	has foo_nx		=> ( index		=> 1,	isa => 'Str',	is => 'rw',	);
	has foo			=> ( 						isa => 'Str',	is => 'rw',	);

	sub _build_foo_de { 'LAZY BUILD' }

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag "Create...";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $foo;

	lives_ok
	{
		$foo	= Foo->new
		(
			id				=> 'FOO_1',
			foo_tr_def	=> 'foo_transient_set',		#	beware of dragons
			foo_tr		=> 'foo_transient',			#	beware of dragons
			foo_vi_def	=> 'foo_virtual_set',		#	beware of dragons
			foo_vi		=> 'foo_virtual',				#	beware of dragons
			foo_de		=> 'foo_derived',				#	ignored
			foo_nx		=>	'foo_index',
			foo			=>	'foo',
			asylum		=> $ASYL,
		);
	}	'foo constructed';

	is		$foo->id,			'FOO_1',					'got id';
	is		$foo->foo_tr_def,	'foo_transient_set',	'got transient set value';				#	present
	is		$foo->foo_tr,		'foo_transient',		'got transient value';					#	present
	is		$foo->foo_vi_def,	'foo_virtual_set',	'got virtual set value';				#	present
	is		$foo->foo_vi,		'foo_virtual',			'got virtual value';						#	present
	is		$foo->foo_de,		'LAZY BUILD',			'got default derived value';			#	was ignored
	is		$foo->foo_nx,		'foo_index',			'got index value';
	is		$foo->foo,			'foo',					'got foo value';

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag "Evoke...";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my ( @param, @a, @a_e );

	@param	= ( 'Foo', 'foo', 'foo_nx' );

	@a	= $ASYL->find ( @param );	@a_e	= qw( FOO_1 foo_index );	cmp_deeply	\@a, bag(@a_e),	"find 'foo' (@a_e)";

	my $id	= $ASYL->find ( @param );

	is		$id,	'FOO_1',	"found '$id' for 'foo'";

	my $foo;

	lives_ok
	{
		$foo	= Foo->new
		(
			id			=> $id,
			asylum	=> $ASYL,
			foo		=> 'new foo',		#	ignored
		);
	}	'foo reloaded';

	is		$foo->id,			'FOO_1',					'got id';
	is		$foo->foo_tr_def,	'TRANSIENT DEFAULT',	'got default transient value';		#	gone after reload, but has default
	is		$foo->foo_tr,		undef,					'no transient value';					#	gone after reload
	is		$foo->foo_vi_def,	'VIRTUAL DEFAULT',	'got default virtual value';			#	gone after reload, but has default
	is		$foo->foo_vi,		undef,					'no virtual value';						#	gone after reload
	is		$foo->foo_de,		'LAZY BUILD',			'got default derived value';			#	was ignored
	is		$foo->foo_nx,		'foo_index',			'got index value';
	is		$foo->foo,			'foo',					'got foo value';							#	was ignored

	lives_ok	{ $ASYL->remove;	}	'Asylum removed';
}

diag "Create...";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	{
		my $foo;

		lives_ok
		{
			$foo	= Foo->new
			(
				id				=> 'FOO_1',
				foo_tr_def	=> 'foo_transient_set',		#	beware of dragons
				foo_tr		=> 'foo_transient',			#	beware of dragons
				foo_vi_def	=> 'foo_virtual_set',		#	beware of dragons
				foo_vi		=> 'foo_virtual',				#	beware of dragons
				foo_de		=> 'foo_derived',				#	ignored
				foo_nx		=>	'foo_index',
				foo			=>	'foo',
				asylum	=> $ASYL,
			);
		}	'foo constructed';

		is		$foo->id,			'FOO_1',					'got id';
		is		$foo->foo_tr_def,	'foo_transient_set',	'got transient set value';				#	present
		is		$foo->foo_tr,		'foo_transient',		'got transient value';					#	present
		is		$foo->foo_vi_def,	'foo_virtual_set',	'got virtual set value';				#	present
		is		$foo->foo_vi,		'foo_virtual',			'got virtual value';						#	present
		is		$foo->foo_de,		'LAZY BUILD',			'got default derived value';			#	was ignored
		is		$foo->foo_nx,		'foo_index',			'got index value';
		is		$foo->foo,			'foo',					'got foo value';
	}

	diag 'foo out of scope...';

	{
		my $foo;

		lives_ok
		{
			$foo	= Foo->new
			(
				id			=> 'FOO_1',
				asylum	=> $ASYL,
			);
		}	'foo constructed';

		is		$foo->id,			'FOO_1',					'got id';
		is		$foo->foo_tr_def,	'TRANSIENT DEFAULT',	'got default transient value';		#	gone after scope, but has default
		is		$foo->foo_tr,		undef,					'no transient value';					#	gone after scope
		is		$foo->foo_vi_def,	'foo_virtual_set',	'got virtual set value';				#	present
		is		$foo->foo_vi,		'foo_virtual',			'got virtual value';						#	present
		is		$foo->foo_de,		'LAZY BUILD',			'got default derived value';			#	was ignored
		is		$foo->foo_nx,		'foo_index',			'got index value';
		is		$foo->foo,			'foo',					'got foo value';							#	was ignored

		diag 'but we can do:';

		lives_ok	{ $foo->foo_tr_def	( 'new foo_transient_set' ); }		'set new foo_transient_set';
		lives_ok	{ $foo->foo_tr			( 'new foo_transient' ); }				'set new foo_transient';

		is		$foo->foo_tr_def,	'new foo_transient_set',	'got new transient value_set';	#	now present
		is		$foo->foo_tr,		'new foo_transient',			'got new transient value';			#	now present
	}

	diag 'foo out of scope again...';

	{
		my $foo;

		lives_ok
		{
			$foo	= Foo->new
			(
				id			=> 'FOO_1',
				asylum	=> $ASYL,
			);
		}	'foo constructed';

		is		$foo->id,			'FOO_1',					'got id';
		is		$foo->foo_tr_def,	'TRANSIENT DEFAULT',	'got default transient value';		#	gone after scope, but has default
		is		$foo->foo_tr,		undef,					'no transient value';					#	gone after scope again
		is		$foo->foo_vi_def,	'foo_virtual_set',	'got virtual set value';				#	present
		is		$foo->foo_vi,		'foo_virtual',			'got virtual value';						#	present
		is		$foo->foo_de,		'LAZY BUILD',			'got default derived value';			#	was ignored
		is		$foo->foo_nx,		'foo_index',			'got index value';
		is		$foo->foo,			'foo',					'got foo value';							#	was ignored
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

