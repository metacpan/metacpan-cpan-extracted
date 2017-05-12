#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 79;
#use Test::More 'no_plan';

use_ok 'Frost::Cemetery';

{
	package Foo;			#	must exist for type ClassName

	use Moose;

	has id	=> ( is => 'rw', isa => 'Str' );		#	must exist for attribute check
	has num	=> ( is => 'rw', isa => 'Int' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Bar;			#	must exist for type ClassName

	use Moose;
	extends 'Foo';

	has id		=> ( is => 'rw', isa => 'Int' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my ( $cemetery_foo, $cemetery_bar );

lives_ok { $cemetery_foo = Frost::Cemetery->new ( classname => 'Foo', slotname => 'num', data_root => $TMP_PATH ); }
	'new cemetery_foo';
lives_ok { $cemetery_bar = Frost::Cemetery->new ( classname => 'Bar', slotname => 'num', data_root => $TMP_PATH ); }
	'new cemetery_bar';

my ( @a, @a_e );

is		$cemetery_foo->entomb ( 22,	122,		),	true,		'cemetery_foo entomb 122';
is		$cemetery_foo->entomb ( 11,	111,		),	true,		'cemetery_foo entomb 111';
is		$cemetery_foo->entomb ( 2,		102,		),	true,		'cemetery_foo entomb 102';
is		$cemetery_foo->entomb ( 1,		101,		),	true,		'cemetery_foo entomb 101';
is		$cemetery_foo->entomb ( 42,	142,		),	true,		'cemetery_foo entomb 142';

is		$cemetery_foo->forget ( 42 ),					true,		'cemetery_foo forget 142';

is		$cemetery_foo->exhume ( 22,		),			122,		'cemetery_foo exhume 122';
is		$cemetery_foo->exhume ( 11,		),			111,		'cemetery_foo exhume 111';
is		$cemetery_foo->exhume ( 2,			),			102,		'cemetery_foo exhume 102';
is		$cemetery_foo->exhume ( 1,			),			101,		'cemetery_foo exhume 101';
isnt	$cemetery_foo->exhume ( 42 		),			142,		'cemetery_foo exhume 142 fails';

is		$cemetery_bar->entomb ( 22,	222,		),	true,		'cemetery_bar entomb 122';
is		$cemetery_bar->entomb ( 11,	211,		),	true,		'cemetery_bar entomb 111';
is		$cemetery_bar->entomb ( 2,		202,		),	true,		'cemetery_bar entomb 102';
is		$cemetery_bar->entomb ( 1,		201,		),	true,		'cemetery_bar entomb 1011';
is		$cemetery_bar->entomb ( 42,	242,		),	true,		'cemetery_bar entomb 142';

is		$cemetery_bar->forget ( 42 ),					true,		'cemetery_bar forget 142';

is		$cemetery_bar->exhume ( 22,		),			222,		'cemetery_bar exhume 222';
is		$cemetery_bar->exhume ( 11,		),			211,		'cemetery_bar exhume 211';
is		$cemetery_bar->exhume ( 2,			),			202,		'cemetery_bar exhume 202';
is		$cemetery_bar->exhume ( 1,			),			201,		'cemetery_bar exhume 201';
isnt	$cemetery_bar->exhume ( 42 		),			242,		'cemetery_bar exhume 242 fails';

is		$cemetery_foo->count(),	4,			'cemetery_foo has 4 essences';
is		$cemetery_bar->count(),	4,			'cemetery_bar has 4 essences';

@a		= $cemetery_foo->exhume ( 22 );		@a_e	= qw( 122 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo exhume (122)';
@a		= $cemetery_foo->exhume ( 11 );		@a_e	= qw( 111 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo exhume (111)';

@a		= $cemetery_bar->exhume ( 22 );		@a_e	= qw( 222 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar exhume (222)';
@a		= $cemetery_bar->exhume ( 11 );		@a_e	= qw( 211 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar exhume (211)';

#	Don't use the dump of _dbm_hash for verifying...
#IS_DEBUG and DEBUG Dump [ $cemetery_foo, $cemetery_bar ], [qw( cemetery_foo cemetery_bar )];

#	SCALAR context
#
is		$cemetery_foo->first(),		1,			'cemetery_foo first 1';				#	ascii sorted
is		$cemetery_foo->next(),		11,		'cemetery_foo next  11';
is		$cemetery_foo->next(),		2,			'cemetery_foo next  2';
is		$cemetery_foo->next(),		22,		'cemetery_foo next  22';
is		$cemetery_foo->next(),		'',		'cemetery_foo no next';

is		$cemetery_foo->last(),		22,		'cemetery_foo last  22';			#	ascii sorted
is		$cemetery_foo->prev(),		2,			'cemetery_foo prev  2';
is		$cemetery_foo->prev(),		11,		'cemetery_foo prev  11';
is		$cemetery_foo->prev(),		1,			'cemetery_foo prev  1';
is		$cemetery_foo->prev(),		'',		'cemetery_foo no prev';

is		$cemetery_bar->first(),		1,			'cemetery_bar first  1';		#	numeric sorted
is		$cemetery_bar->next(),		2,			'cemetery_bar next   2';
is		$cemetery_bar->next(),		11,		'cemetery_bar next  11';
is		$cemetery_bar->next(),		22,		'cemetery_bar next  22';
is		$cemetery_bar->next(),		'',		'cemetery_bar no next';

is		$cemetery_bar->last(),		22,		'cemetery_bar last  22';		#	numeric sorted
is		$cemetery_bar->prev(),		11,		'cemetery_bar prev  11';
is		$cemetery_bar->prev(),		2,			'cemetery_bar prev   2';
is		$cemetery_bar->prev(),		1,			'cemetery_bar prev   1';
is		$cemetery_bar->prev(),		'',		'cemetery_bar no prev';

#	LIST context
#
@a	= $cemetery_foo->first();	@a_e	= qw( 1	101 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo first 1';			#	ascii sorted
@a	= $cemetery_foo->next();	@a_e	= qw( 11	111 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo next  11';
@a	= $cemetery_foo->next();	@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo next  2';
@a	= $cemetery_foo->next();	@a_e	= qw( 22 122 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo next  22';
@a	= $cemetery_foo->next();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'cemetery_foo no next';

@a	= $cemetery_foo->last();	@a_e	= qw( 22	122 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo last  22';		#	ascii sorted
@a	= $cemetery_foo->prev();	@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo prev  2';
@a	= $cemetery_foo->prev();	@a_e	= qw( 11	111 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo prev  11';
@a	= $cemetery_foo->prev();	@a_e	= qw( 1	101 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo prev  1';
@a	= $cemetery_foo->prev();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'cemetery_foo no prev';

@a	= $cemetery_bar->first();	@a_e	= qw( 1	201 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar first  1';		#	numeric sorted
@a	= $cemetery_bar->next();	@a_e	= qw( 2	202 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar next   2';
@a	= $cemetery_bar->next();	@a_e	= qw( 11	211 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar next  11';
@a	= $cemetery_bar->next();	@a_e	= qw( 22 222 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar next  22';
@a	= $cemetery_bar->next();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'cemetery_bar no next';

@a	= $cemetery_bar->last();	@a_e	= qw( 22	222 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar last  22';		#	numeric sorted
@a	= $cemetery_bar->prev();	@a_e	= qw( 11	211 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar prev  11';
@a	= $cemetery_bar->prev();	@a_e	= qw( 2	202 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar prev  2';
@a	= $cemetery_bar->prev();	@a_e	= qw( 1	201 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_bar prev  1';
@a	= $cemetery_bar->prev();	@a_e	= qw();				cmp_deeply	\@a, bag(@a_e),	'cemetery_bar no prev';

@a	= $cemetery_foo->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo first 2';
@a	= $cemetery_foo->next ( 2 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'cemetery_foo no next 2';

@a	= $cemetery_foo->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo first 2';
@a	= $cemetery_foo->prev ( 2 );		@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'cemetery_foo no prev 2';

@a	= $cemetery_foo->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo first 2';
@a	= $cemetery_foo->next ();			@a_e	= qw( 22	122 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo next 2 is 22 (no key)';

@a	= $cemetery_foo->first ( 2 );		@a_e	= qw( 2	102 );	cmp_deeply	\@a, bag(@a_e),	'cemetery_foo first 2';
@a	= $cemetery_foo->prev ();			@a_e	= qw( 11	111);		cmp_deeply	\@a, bag(@a_e),	'cemetery_foo prev 2 is 11 (no key)';



