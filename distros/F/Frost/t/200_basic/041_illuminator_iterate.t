#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 107;
#use Test::More 'no_plan';

use_ok 'Frost::Illuminator';

{
	package Foo;			#	must exist for type ClassName

	#	Just testing - DON'T TRY THIS AT HOME!
	#	Always say "use Frost"...
	#
	use Moose;

	Moose::Util::MetaRole::apply_metaroles
	(
		for						=> __PACKAGE__,
		class_metaroles		=>
		{
			attribute			=> [ 'Frost::Meta::Attribute' ],
		}
	);

	has mul	=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check
	has uni	=> ( index => 'unique',	is => 'rw', isa => 'Str' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my ( $illuminator_mul, $illuminator_uni );

lives_ok { $illuminator_mul = Frost::Illuminator->new ( classname => 'Foo', slotname => 'mul', data_root => $TMP_PATH ); }
	'new illuminator_mul';
lives_ok { $illuminator_uni = Frost::Illuminator->new ( classname => 'Foo', slotname => 'uni', data_root => $TMP_PATH ); }
	'new illuminator_uni';

my ( @a, @a_e );

is		$illuminator_mul->collect ( 22,	122,		),	true,		'illuminator_mul collect 122';
is		$illuminator_mul->collect ( 11,	111,		),	true,		'illuminator_mul collect 111';
is		$illuminator_mul->collect ( 2,	102,		),	true,		'illuminator_mul collect 102';
is		$illuminator_mul->collect ( 1,	101,		),	true,		'illuminator_mul collect 101';
is		$illuminator_mul->collect ( 42,	142,		),	true,		'illuminator_mul collect 142';
is		$illuminator_mul->collect ( 42,	444,		),	true,		'illuminator_mul collect 442';
is		$illuminator_mul->collect ( 42,	555,		),	true,		'illuminator_mul collect 542';

is		$illuminator_mul->lookup ( 22,		),			122,		'illuminator_mul lookup 122';
is		$illuminator_mul->lookup ( 11,		),			111,		'illuminator_mul lookup 111';
is		$illuminator_mul->lookup ( 2,			),			102,		'illuminator_mul lookup 102';
is		$illuminator_mul->lookup ( 1,			),			101,		'illuminator_mul lookup 101';
is		$illuminator_mul->lookup ( 42 		),			142,		'illuminator_mul lookup 142';	#	as entered...

is		$illuminator_uni->collect ( 22,	222,		),	true,		'illuminator_uni collect 122';
is		$illuminator_uni->collect ( 11,	211,		),	true,		'illuminator_uni collect 111';
is		$illuminator_uni->collect ( 2,	202,		),	true,		'illuminator_uni collect 102';
is		$illuminator_uni->collect ( 1,	201,		),	true,		'illuminator_uni collect 1011';
is		$illuminator_uni->collect ( 42,	242,		),	true,		'illuminator_uni collect 142';
is		$illuminator_uni->collect ( 42,	666,		),	true,		'illuminator_uni collect 666';
is		$illuminator_uni->collect ( 42,	777,		),	true,		'illuminator_uni collect 777';

is		$illuminator_uni->lookup ( 22,		),			222,		'illuminator_uni lookup 222';
is		$illuminator_uni->lookup ( 11,		),			211,		'illuminator_uni lookup 211';
is		$illuminator_uni->lookup ( 2,			),			202,		'illuminator_uni lookup 202';
is		$illuminator_uni->lookup ( 1,			),			201,		'illuminator_uni lookup 201';
is		$illuminator_uni->lookup ( 42 		),			777,		'illuminator_uni lookup 777';	#	unique...

#	Don't use the dump of _dbm_hash for verifying...
#IS_DEBUG and DEBUG Dump [ $illuminator_mul, $illuminator_uni ], [qw( illuminator_mul illuminator_uni )];

is		$illuminator_mul->count(),	7,			'illuminator_mul has 7 entries';
is		$illuminator_uni->count(),	5,			'illuminator_uni has 5 entries';

@a		= $illuminator_mul->lookup ( 22 );		@a_e	= qw( 122 );			cmp_deeply	\@a, bag(@a_e),	'illuminator_mul lookup (122)';
@a		= $illuminator_mul->lookup ( 11 );		@a_e	= qw( 111 );			cmp_deeply	\@a, bag(@a_e),	'illuminator_mul lookup (111)';
@a		= $illuminator_mul->lookup ( 42 );		@a_e	= qw( 142 444 555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul lookup (142 444 555)';

@a		= $illuminator_uni->lookup ( 22 );		@a_e	= qw( 222 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni lookup (222)';
@a		= $illuminator_uni->lookup ( 11 );		@a_e	= qw( 211 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni lookup (211)';
@a		= $illuminator_uni->lookup ( 42 );		@a_e	= qw( 777 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni lookup (777)';

#	SCALAR context
#
is		$illuminator_mul->first(),		1,			'illuminator_mul first 1';				#	ascii sorted
is		$illuminator_mul->next(),		11,		'illuminator_mul next  11';
is		$illuminator_mul->next(),		2,			'illuminator_mul next  2';
is		$illuminator_mul->next(),		22,		'illuminator_mul next  22';
is		$illuminator_mul->next(),		42,		'illuminator_mul next  42';
is		$illuminator_mul->next(),		42,		'illuminator_mul next  42';
is		$illuminator_mul->next(),		42,		'illuminator_mul next  42';
is		$illuminator_mul->next(),		'',		'illuminator_mul no next';

is		$illuminator_mul->last(),		42,		'illuminator_mul last  42';
is		$illuminator_mul->prev(),		42,		'illuminator_mul prev  42';
is		$illuminator_mul->prev(),		42,		'illuminator_mul prev  42';
is		$illuminator_mul->prev(),		22,		'illuminator_mul prev  22';
is		$illuminator_mul->prev(),		2,			'illuminator_mul prev  2';
is		$illuminator_mul->prev(),		11,		'illuminator_mul prev  11';
is		$illuminator_mul->prev(),		1,			'illuminator_mul prev  1';
is		$illuminator_mul->prev(),		'',		'illuminator_mul no prev';

is		$illuminator_uni->first(),		1,			'illuminator_uni first  1';
is		$illuminator_uni->next(),		11,		'illuminator_uni next  11';
is		$illuminator_uni->next(),		2,			'illuminator_uni next   2';
is		$illuminator_uni->next(),		22,		'illuminator_uni next  22';
is		$illuminator_uni->next(),		42,		'illuminator_uni next  42';
is		$illuminator_uni->next(),		'',		'illuminator_uni no next';

is		$illuminator_uni->last(),		42,		'illuminator_uni last  42';
is		$illuminator_uni->prev(),		22,		'illuminator_uni next  22';
is		$illuminator_uni->prev(),		2,			'illuminator_uni prev   2';
is		$illuminator_uni->prev(),		11,		'illuminator_uni prev  11';
is		$illuminator_uni->prev(),		1,			'illuminator_uni prev   1';
is		$illuminator_uni->prev(),		'',		'illuminator_uni no prev';

#	LIST context
#
@a	= $illuminator_mul->first();	@a_e	= qw( 1	101 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 1';			#	ascii sorted
@a	= $illuminator_mul->next();	@a_e	= qw( 11	111 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  11';
@a	= $illuminator_mul->next();	@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  2';
@a	= $illuminator_mul->next();	@a_e	= qw( 22 122 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  22';
@a	= $illuminator_mul->next();	@a_e	= qw( 42 142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  42';		#	as entered
@a	= $illuminator_mul->next();	@a_e	= qw( 42 444 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  42';		#	as entered
@a	= $illuminator_mul->next();	@a_e	= qw( 42 555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  42';		#	as entered
@a	= $illuminator_mul->next();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no next';

@a	= $illuminator_mul->last();	@a_e	= qw( 42	555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul last  42';		#	as entered
@a	= $illuminator_mul->prev();	@a_e	= qw( 42 444 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42';		#	as entered
@a	= $illuminator_mul->prev();	@a_e	= qw( 42 142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42';		#	as entered
@a	= $illuminator_mul->prev();	@a_e	= qw( 22	122 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  22';
@a	= $illuminator_mul->prev();	@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  2';
@a	= $illuminator_mul->prev();	@a_e	= qw( 11	111 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  11';
@a	= $illuminator_mul->prev();	@a_e	= qw( 1	101 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  1';
@a	= $illuminator_mul->prev();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no prev';

@a	= $illuminator_uni->first();	@a_e	= qw( 1	201 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni first  1';
@a	= $illuminator_uni->next();	@a_e	= qw( 11	211 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni next  11';
@a	= $illuminator_uni->next();	@a_e	= qw( 2	202 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni next   2';
@a	= $illuminator_uni->next();	@a_e	= qw( 22 222 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni next  22';
@a	= $illuminator_uni->next();	@a_e	= qw( 42 777 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni next  42';
@a	= $illuminator_uni->next();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'illuminator_uni no next';

@a	= $illuminator_uni->last();	@a_e	= qw( 42	777 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni last  42';
@a	= $illuminator_uni->prev();	@a_e	= qw( 22	222 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni prev  22';
@a	= $illuminator_uni->prev();	@a_e	= qw( 2	202 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni prev  2';
@a	= $illuminator_uni->prev();	@a_e	= qw( 11	211 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni prev  11';
@a	= $illuminator_uni->prev();	@a_e	= qw( 1	201 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_uni prev  1';
@a	= $illuminator_uni->prev();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'illuminator_uni no prev';

@a	= $illuminator_mul->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 2';
@a	= $illuminator_mul->next ( 2 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no next 2';

@a	= $illuminator_mul->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 2';
@a	= $illuminator_mul->prev ( 2 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no prev 2';

@a	= $illuminator_mul->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 2';
@a	= $illuminator_mul->next ();			@a_e	= qw( 22	122 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next 2 is 22 (no key)';

@a	= $illuminator_mul->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 2';
@a	= $illuminator_mul->prev ();			@a_e	= qw( 11	111);		cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev 2 is 11 (no key)';

@a	= $illuminator_mul->first ( 42 );	@a_e	= qw( 42	142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul first 42';
@a	= $illuminator_mul->next ( 42 );		@a_e	= qw( 42	444 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  42';
@a	= $illuminator_mul->next ( 42 );		@a_e	= qw( 42	555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul next  42';
@a	= $illuminator_mul->next ( 42 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no next 42';

#############
#	CAVEAT	#
#############

#	expected
#
#@a	= $illuminator_mul->last ( 42 );		@a_e	= qw( 42	555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul last  42';
#@a	= $illuminator_mul->prev ( 42 );		@a_e	= qw( 42	444 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42';
#@a	= $illuminator_mul->prev ( 42 );		@a_e	= qw( 42	142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42';
#@a	= $illuminator_mul->prev ( 42 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no prev 42';

#	found
#
@a	= $illuminator_mul->last ( 42 );		@a_e	= qw( 42	142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul last  42';
@a	= $illuminator_mul->prev ( 42 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'illuminator_mul no prev 42';

#	expected
#
#@a	= $illuminator_mul->last ( 42 );		@a_e	= qw( 42	555 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul last  42';
#@a	= $illuminator_mul->prev ();			@a_e	= qw( 42	444 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42 is 42 (no key)';
#@a	= $illuminator_mul->prev ();			@a_e	= qw( 42	142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42 is 42 (no key)';
#@a	= $illuminator_mul->prev ();			@a_e	= qw( 22 122 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42 is 22 (no key)';

#	found
#
@a	= $illuminator_mul->last ( 42 );		@a_e	= qw( 42	142 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul last  42';
@a	= $illuminator_mul->prev ();			@a_e	= qw( 22 122 );	cmp_deeply	\@a, bag(@a_e),	'illuminator_mul prev  42 is 22 (no key)';

#
#############
