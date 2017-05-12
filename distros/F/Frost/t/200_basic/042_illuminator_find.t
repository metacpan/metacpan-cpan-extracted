#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 47;
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

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my ( $illuminator_mul );

lives_ok { $illuminator_mul = Frost::Illuminator->new ( classname => 'Foo', slotname => 'mul', data_root => $TMP_PATH ); }
	'new illuminator_mul';

my ( @a, @a_e );

#	from DB_File-1.820/t/db-btree.t
#	slightly different...

is		$illuminator_mul->collect ( 'mouse',	'mickey' ), 	true,		'set mickey mouse';
is		$illuminator_mul->collect ( 'Wall',		'Larry'	), 	true,		'set Larry Wall';
is		$illuminator_mul->collect ( 'Wall',		'Stone'	), 	true,		'set Stone Wall';		# Note the duplicate key
is		$illuminator_mul->collect ( 'Wall',		'Brick'	), 	true,		'set Brick Wall';		# Note the duplicate key
is		$illuminator_mul->collect ( 'Wall',		'Brick'	), 	true,		'set Brick Wall';		# Note the duplicate key and value
is		$illuminator_mul->collect ( 'Smith',	'John'	), 	true,		'set John Smith';

is		$illuminator_mul->count ( 'Unkown' ), 	0,			"has no entry  for Unknown";
is		$illuminator_mul->count ( 'Smith' ), 	1,			"has 1 entry   for Smith";
is		$illuminator_mul->count ( 'Wall' ), 	4,			"has 4 entries for Wall";
is		$illuminator_mul->count(), 				6,			'has 6 entries';

@a	= $illuminator_mul->lookup ( 'Unknown'	);		@a_e	= ();										cmp_deeply	\@a, bag(@a_e),	'get Unknown';
@a	= $illuminator_mul->lookup ( 'Smith'	);		@a_e	= qw( John );							cmp_deeply	\@a, bag(@a_e),	'get Smith';
@a	= $illuminator_mul->lookup ( 'Wall'		);		@a_e	= qw( Larry Stone Brick Brick );	cmp_deeply	\@a, bag(@a_e),	'get Wall';

@a	= $illuminator_mul->first ();	@a_e	= qw( John Smith );		cmp_deeply	\@a, bag(@a_e),	"first (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= qw( Larry Wall );		cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= qw( Stone Wall );		cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= qw( Brick Wall );		cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= qw( Brick Wall );		cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= qw( mickey mouse );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $illuminator_mul->next ();	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"no next";

@a	= $illuminator_mul->find			( 'Wa' );	@a_e	= qw( Larry Wall );	cmp_deeply	\@a, bag(@a_e),	"find      'Wa' (@a_e)";
@a	= $illuminator_mul->find_next		( 'Wa' );	@a_e	= qw( Stone Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $illuminator_mul->find_next		( 'Wa' );	@a_e	= qw( Brick Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $illuminator_mul->find_next		( 'Wa' );	@a_e	= qw( Brick Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $illuminator_mul->find_next		( 'Wa' );	@a_e	= ();						cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' no next";

@a	= $illuminator_mul->find			( 'A' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"find       'A' none";
@a	= $illuminator_mul->find_next		( 'A' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"find_next  'A' none";

@a	= $illuminator_mul->match			( 'A' );	@a_e	= qw( John Smith );		cmp_deeply	\@a, bag(@a_e),	"match      'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= qw( Larry Wall );		cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= qw( Stone Wall );		cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= qw( Brick Wall );		cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= qw( Brick Wall );		cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= qw( mickey mouse );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $illuminator_mul->match_next	( 'A' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"match_next 'A' no next";

@a	= $illuminator_mul->find			( 'a' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"find       'a' none";
@a	= $illuminator_mul->find_next		( 'a' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"find_next  'a' none";

@a	= $illuminator_mul->match			( 'a' );	@a_e	= qw( mickey mouse );	cmp_deeply	\@a, bag(@a_e),	"match      'a' (@a_e)";
@a	= $illuminator_mul->match_next	( 'a' );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"match_next 'a' none";

lives_ok	{ $illuminator_mul->clear; }	'cleared';

lives_ok
{
	$illuminator_mul->collect ( '2009-07-10',	'A1' );
	$illuminator_mul->collect ( '2009-07-10',	'A2' );
	$illuminator_mul->collect ( '2009-07-10',	'A3' );
	$illuminator_mul->collect ( '2009-08-10',	'B10' );
	$illuminator_mul->collect ( '2009-07-11',	'A11' );
	$illuminator_mul->collect ( '2009-07-12',	'A12' );
	$illuminator_mul->collect ( '2010-07-10',	'X10' );
	$illuminator_mul->collect ( '2009-06-30',	'A30' );
}	'set some dates';

{
	#	first do a match to find the nearest date
	#
	my $start	= '2009-07-01';

	@a	= $illuminator_mul->match ( $start );	@a_e	= qw( 2009-07-10 A1 );	cmp_deeply	\@a, bag(@a_e),	"match $start -> (@a_e)";

	#	get this date and proceed with cursor
	#
	my $date		= $a[0];

	@a	= $illuminator_mul->next ( $date );	@a_e	= qw( 2009-07-10 A2 );	cmp_deeply	\@a, bag(@a_e),	"next  (@a_e)";
	@a	= $illuminator_mul->next ( $date );	@a_e	= qw( 2009-07-10 A3 );	cmp_deeply	\@a, bag(@a_e),	"next  (@a_e)";
	@a	= $illuminator_mul->next ( $date );	@a_e	= ();							cmp_deeply	\@a, bag(@a_e),	"no next";
}

{
	#	more date handling
	#
	my $from		= '2009-07-01';
	my $to		= '2009-07-31';
	my $current	= '';

	my @values	= ();

	@a	= $illuminator_mul->match ( $from );
	$current	= $a[0];

	while ( @a and ( $current le $to ) )
	{
		push @values, $a[1];

		@a	= $illuminator_mul->next();
		$current	= $a[0];
	}

	cmp_deeply	\@values, bag ( qw( A1 A2 A3 A11 A12 ) ),	"got all values from $from to $to";
}
