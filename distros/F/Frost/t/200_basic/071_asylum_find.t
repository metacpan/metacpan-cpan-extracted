#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 85;
#use Test::More 'no_plan';

use_ok 'Frost::Asylum';

BEGIN
{
	{
		package Frost::Meta::Class;		#	expensive version !!!!!!

		use Moose::Role;

		use Frost::Util;

		sub is_readonly	{ $_[0]->_is_feature ( $_[1], 'readonly'	);	}
		sub is_transient	{ $_[0]->_is_feature ( $_[1], 'transient'	);	}
		sub is_derived		{ $_[0]->_is_feature ( $_[1], 'derived'	);	}
		sub is_virtual		{ $_[0]->_is_feature ( $_[1], 'virtual'	);	}
		sub is_index		{ $_[0]->_is_feature ( $_[1], 'index'		);	}
		sub is_unique		{ $_[0]->_is_feature ( $_[1], 'unique'		);	}
		sub is_auto_id		{ $_[0]->_is_feature ( $_[1], 'auto_id'	);	}
		sub is_auto_inc	{ $_[0]->_is_feature ( $_[1], 'auto_inc'	);	}

		sub _is_feature
		{
			my ( $self, $attr_name, $feature )	= @_;

			my $class	= $self->name;

			my $attr		= find_attribute_manuel $class, $attr_name;

			my $method	= 'is_' . $feature;

			my $result	= $attr->$method();

			return $result;
		}

		no Moose::Role;
	}
}

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
			class					=> [ 'Frost::Meta::Class'		],
			attribute			=> [ 'Frost::Meta::Attribute' ],
		}
	);

	has id		=> ( 						isa => 'Int',	is => 'ro' );
	has _dirty	=> ( virtual	=> 1,	isa => 'Bool',	is => 'ro' );

	has lastname	=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check
	has firstname	=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check

	has date			=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my ( $asylum );

lives_ok { $asylum = Frost::Asylum->new ( classname => 'Foo', data_root => $TMP_PATH ); }
	'new asylum';

my ( @a, @a_e );

#	from DB_File-1.820/t/db-btree.t
#	slightly different...

#	DON'T TRY THIS AT HOME,
#	use only the API methods below...
#
#	The following stuff will be done by Frost::Locum magi-, automati- and what-ever-cally!
#
my $data	=
{
	1	=> { firstname => 'mickey',	lastname => 'mouse',	},
	2	=> { firstname => 'Larry',		lastname => 'Wall',	},
	3	=> { firstname => 'Stone',		lastname => 'Wall',	},		# Note the duplicate key
	4	=> { firstname => 'Brick',		lastname => 'Wall',	},		# Note the duplicate key
	5	=> { firstname => 'Brick',		lastname => 'Wall',	},		# Note the duplicate key and value
	6	=> { firstname => 'John',		lastname => 'Smith',	},
};

#	prepare test...
#
foreach my $id ( sort keys %$data )
{
	for my $slot ( qw( firstname lastname ) )
	{
		is		$asylum->_silence ( 'Foo', $id, $slot, $data->{$id}->{$slot} ),	true,		"_silence Foo $id $slot";		#	auto-create of id-spirit
	}
	is		$asylum->_silence ( 'Foo', $id, '_dirty', true ),	true,		"_silence Foo $id _dirty manually";
}

lives_ok	{ $asylum->close; }		'asylum saved and closed';

$asylum	= undef;		#	force auto-open and -reload

lives_ok	{ $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'asylum re-created';

#	API methods:
#
is		$asylum->count ( 'Foo', 'Unkown',	'lastname', true ), 	0,			"illuminator has no entry   for Unknown";
is		$asylum->count ( 'Foo', 'Smith',		'lastname', true ), 	1,			"illuminator has  1 entry   for Smith";
is		$asylum->count ( 'Foo', 'Wall',		'lastname', true ), 	4,			"illuminator has  4 entries for Wall";
is		$asylum->count ( 'Foo' ), 											6,			'cemetery    has  6 entries';

@a	= $asylum->lookup ( 'Foo', 'Unknown',	'lastname'	);	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	'get Unknown';
@a	= $asylum->lookup ( 'Foo', 'Smith',		'lastname'	);	@a_e	= qw( 6 );			cmp_deeply	\@a, bag(@a_e),	'get Smith';
@a	= $asylum->lookup ( 'Foo', 'Wall',		'lastname'	);	@a_e	= qw( 2 3 4 5 );	cmp_deeply	\@a, bag(@a_e),	'get Wall';

my @param;

@param	= ( 'Foo', undef, 'lastname' );

@a	= $asylum->first	( @param );	@a_e	= qw( 6 Smith );	cmp_deeply	\@a, bag(@a_e),	"first (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 2 Wall );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 3 Wall );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 4 Wall );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 5 Wall );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 1 mouse );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"no next";

@param	= ( 'Foo', undef, 'firstname' );

@a	= $asylum->first	( @param );	@a_e	= qw( 4 Brick );	cmp_deeply	\@a, bag(@a_e),	"first (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 5 Brick );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 6 John );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 2 Larry );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 3 Stone );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= qw( 1 mickey );	cmp_deeply	\@a, bag(@a_e),	"next (@a_e)";
@a	= $asylum->next	( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"no next";

@param	= ( 'Foo', 'Wa', 'lastname' );

@a	= $asylum->find			( @param );	@a_e	= qw( 2 Wall );	cmp_deeply	\@a, bag(@a_e),	"find      'Wa' (@a_e)";
@a	= $asylum->find_next		( @param );	@a_e	= qw( 3 Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $asylum->find_next		( @param );	@a_e	= qw( 4 Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $asylum->find_next		( @param );	@a_e	= qw( 5 Wall );	cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' (@a_e)";
@a	= $asylum->find_next		( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"find_next 'Wa' no next";

@param	= ( 'Foo', 'A', 'lastname' );

@a	= $asylum->find			( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"find       'A' none";
@a	= $asylum->find_next		( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"find_next  'A' none";

@a	= $asylum->match			( @param );	@a_e	= qw( 6 Smith );	cmp_deeply	\@a, bag(@a_e),	"match      'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= qw( 2 Wall );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= qw( 3 Wall );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= qw( 4 Wall );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= qw( 5 Wall );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= qw( 1 mouse );	cmp_deeply	\@a, bag(@a_e),	"match_next 'A' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"match_next 'A' no next";

@param	= ( 'Foo', 'a', 'lastname' );

@a	= $asylum->find			( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"find       'a' none";
@a	= $asylum->find_next		( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"find_next  'a' none";

@a	= $asylum->match			( @param );	@a_e	= qw( 1 mouse );	cmp_deeply	\@a, bag(@a_e),	"match      'a' (@a_e)";
@a	= $asylum->match_next	( @param );	@a_e	= ();					cmp_deeply	\@a, bag(@a_e),	"match_next 'a' none";

lives_ok	{ $asylum->clear; }	'cleared';

my $dates	=
{
	90630		=> { date => '2009-06-30' },
	90711		=> { date => '2009-07-11' },
	90712		=> { date => '2009-07-12' },
	90810		=> { date => '2009-08-10' },
	100710	=> { date => '2010-07-10' },
	190710	=> { date => '2009-07-10' },
	290710	=> { date => '2009-07-10' },
	390710	=> { date => '2009-07-10' },
};

#	prepare test...
#
foreach my $id ( sort keys %$dates )
{
	for my $slot ( qw( date ) )
	{
		is		$asylum->_silence ( 'Foo', $id, $slot, $dates->{$id}->{$slot} ),	true,		"_silence Foo $id $slot";		#	auto-create of id-spirit
	}
	is		$asylum->_silence ( 'Foo', $id, '_dirty', true ),	true,		"_silence Foo $id _dirty manually";
}

#DEBUG Dumper $asylum;

lives_ok	{ $asylum->close; }		'asylum saved and closed';

$asylum	= undef;		#	force auto-open and -reload

lives_ok	{ $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'asylum re-created';

{
	#	first do a match to find the nearest date
	#
	my $start	= '2009-07-01';

	my @param	= ( 'Foo', $start, 'date' );

	@a	= $asylum->match ( @param );	@a_e	= qw( 190710 2009-07-10 );	cmp_deeply	\@a, bag(@a_e),	"match $start -> (@a_e)";

	#	get this date and proceed with cursor
	#
	my $date		= $a[0];

	@param	= ( 'Foo', $date, 'date' );

	@a	= $asylum->next ( @param );	@a_e	= qw( 290710 2009-07-10 );	cmp_deeply	\@a, bag(@a_e),	"next  (@a_e)";
	@a	= $asylum->next ( @param );	@a_e	= qw( 390710 2009-07-10 );	cmp_deeply	\@a, bag(@a_e),	"next  (@a_e)";
	@a	= $asylum->next ( @param );	@a_e	= ();								cmp_deeply	\@a, bag(@a_e),	"no next";
}

{
	#	more date handling
	#
	my $from		= '2009-07-01';
	my $to		= '2009-07-31';
	my $current	= '';

	my @ids	= ();

	my @param	= ( 'Foo', $from, 'date' );

	@a	= $asylum->match ( @param );
	$current	= $a[0];

	while ( @a and ( $current le $to ) )
	{
		push @ids, $a[1];

		@a	= $asylum->next ( 'Foo', undef, 'date' );
		$current	= $a[0];
	}

	cmp_deeply	\@ids, bag ( qw( 90711 90712 190710 290710 390710 ) ),	"got all values from $from to $to";
}






