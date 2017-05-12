#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 1304;
#use Test::More 'no_plan';

use Frost::Types;

{
	package Foo;
	use Moose;
	use Frost::Types;

	has 'vSortType'				=> ( is => 'rw', isa => 'Frost::SortType' );
	has 'vStatus'					=> ( is => 'rw', isa => 'Frost::Status' );
	has 'vDate'						=> ( is => 'rw', isa => 'Frost::Date' );
	has 'vTime'						=> ( is => 'rw', isa => 'Frost::Time' );
	has 'vTimeStamp'				=> ( is => 'rw', isa => 'Frost::TimeStamp' );
	has 'vFilePath'				=> ( is => 'rw', isa => 'Frost::FilePath' );
	has 'vFilePathMustExist'	=> ( is => 'rw', isa => 'Frost::FilePathMustExist' );
	has 'vWhole'					=> ( is => 'rw', isa => 'Frost::Whole' );
	has 'vNatural'					=> ( is => 'rw', isa => 'Frost::Natural' );
	has 'vStringId'				=> ( is => 'rw', isa => 'Frost::StringId' );
	has 'vEmailString'			=> ( is => 'rw', isa => 'Frost::EmailString' );
	has 'vUniqueStringId'		=> ( is => 'rw', isa => 'Frost::UniqueStringId' );
	has 'vUniqueId'				=> ( is => 'rw', isa => 'Frost::UniqueId' );

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $GOOD_DIR	= $TMP_PATH;
my $BAD_DIR		= $TMP_PATH_NIX;

my $ARRAY_REF	= [];
my $HASH_REF	= {};
my $SCALAR_REF	= \(my $var);
my $CODE_REF	= sub {};

no warnings 'once'; # << I *hate* that warning ...
my $GLOB_REF	= \*GLOB_REF;

my $FH;
open ( $FH, '<', $0 ) || die "Could not open $0 for the test";

my $FH_OBJ		= bless {}, "IO::Handle";

my $FOO	= Foo->new;

my $REGEX	= qr/../;

my $UUID		= UUID;

my $DA_VALUES	=
[
	0, 1, 100, -100,
	0.555, -0.555,
	'', 'foo', 'Foo', 'FOO',
	'/', $GOOD_DIR, $BAD_DIR,
	$ARRAY_REF, $HASH_REF, $CODE_REF, $SCALAR_REF, $GLOB_REF,
	$FH, $FH_OBJ,
	$FOO,
	$REGEX,
	SORT_INT, SORT_FLOAT, SORT_DATE, SORT_TEXT,
	STATUS_NOT_INITIALIZED, STATUS_EXISTS, STATUS_MISSING,
	'1999-10-03', '99-10-03', '3.10.1999',
	'15:23:41', '15:23',
	'1999-10-03 15:23:41', '1999-10-03-15-23-41', '19991003152341',
	'This_Is_a_String_id_1234', '_ernesto_42', 'X', '--', '-invalid-',
	'ernesto@dienstleistung-kultur.de', 'äöü$localhost',
	'A-B-C-D-1',	$UUID,
];

my $DA_NAMES	= [ @$DA_VALUES ];

unshift @$DA_VALUES,	undef;
unshift @$DA_NAMES,	'undef';

my $DA_WINNERS	=
{
	'Frost::SortType'				=> [ SORT_INT, SORT_FLOAT, SORT_DATE, SORT_TEXT, ],
	'Frost::Status'				=> [ STATUS_NOT_INITIALIZED, STATUS_EXISTS, STATUS_MISSING, ],
	'Frost::Date'					=> [ '1999-10-03', ],
	'Frost::Time'					=> [ '15:23:41', ],
	'Frost::TimeStamp'			=> [ '1999-10-03 15:23:41', ],
	'Frost::FilePath'				=> [ $GOOD_DIR, $BAD_DIR, ],
	'Frost::FilePathMustExist'	=> [ $GOOD_DIR ],
	'Frost::Whole'					=> [ 0, 1, 100, '19991003152341', ],
	'Frost::Natural'				=> [ 1, 100, '19991003152341' ],
	'Frost::StringId'				=> [ 'This_Is_a_String_id_1234', '_ernesto_42', 'X', '--', 'foo', 'Foo', 'FOO', ],
	'Frost::EmailString'			=> [ 'ernesto@dienstleistung-kultur.de' ],
	'Frost::UniqueStringId'		=> [ 	'A-B-C-D-1',	$UUID, ],
};

$DA_WINNERS->{'Frost::StringId'} =
[
	@{$DA_WINNERS->{'Frost::StringId'}},
	@{$DA_WINNERS->{'Frost::SortType'}},
	@{$DA_WINNERS->{'Frost::Status'}},
];

$DA_WINNERS->{'Frost::UniqueId'} =
[
	@{$DA_WINNERS->{'Frost::Natural'}},
	@{$DA_WINNERS->{'Frost::StringId'}},
	@{$DA_WINNERS->{'Frost::EmailString'}},
	@{$DA_WINNERS->{'Frost::UniqueStringId'}},
];

Moose::Util::TypeConstraints->export_type_constraints_as_functions;

diag "DA FUNKY TEZTZ";

{
	no strict 'refs';

	foreach my $type ( sort keys %$DA_WINNERS )
	{
		my $seen	= {};

		foreach my $winner ( @ { $DA_WINNERS->{$type} || [] } )
		{
			my $name		= defined $winner ? $winner : 'undef';

			ok		&$type ( $winner ), "$type '$name' OK";

			$seen->{$name}++;
		}

		for ( my $i = 0; $i < @$DA_VALUES; $i++ )
		{
			my $looser	= $DA_VALUES->[$i];
			my $name		= $DA_NAMES->[$i];

			next	if $seen->{$name};

			ok	!	&$type ( $looser ), " $type '$name' rejected";
		}
	}
}

diag "DA OBJEKT TEZTZ";

{
	foreach my $type ( sort keys %$DA_WINNERS )
	{
		my $seen	= {};

		my $attr	= "v$type";

		$attr		=~ s/Frost:://;		#	0.64 !!!

		foreach my $winner ( @ { $DA_WINNERS->{$type} || [] } )
		{
			my $name		= defined $winner ? $winner : 'undef';

			lives_ok { $FOO->$attr ( $winner ) }	"Foo->$attr ( '$name' ) OK";
			is			$FOO->$attr, $winner,			"Foo->$attr is '$name'";

			$seen->{$name}++;
		}

		for ( my $i = 0; $i < @$DA_VALUES; $i++ )
		{
			my $looser	= $DA_VALUES->[$i];
			my $name		= $DA_NAMES->[$i];

			next	if $seen->{$name};

			throws_ok { $FOO->$attr ( $looser ) }
				qr/Attribute \($attr\) does not pass the type constraint/,
				"Foo->$attr ( '$name' ) rejected";
		}
	}
}

diag "DA MANUEL TEZTZ";

throws_ok	{ find_type_constraint_manuel ( undef, undef )	}	qr/Param class_or_obj missing/,	'find_type_constraint_manuel';
throws_ok	{ find_type_constraint_manuel ( 'Qaz', undef )	}	qr/Param name missing/,				'find_type_constraint_manuel';
throws_ok	{ find_type_constraint_manuel ( 'Foo', undef )	}	qr/Param name missing/,				'find_type_constraint_manuel';

is ( find_type_constraint_manuel ( 'Qaz', 'vZoot' ), 		undef,		'find_type_constraint_manuel' );
is ( find_type_constraint_manuel ( 'Qaz', 'vStringId' ), undef,		'find_type_constraint_manuel' );

is ( find_type_constraint_manuel ( 'Foo', 'vZoot' ), 		undef,		'find_type_constraint_manuel' );
is ( find_type_constraint_manuel ( 'Foo', 'vStringId' ),	'Frost::StringId',	'find_type_constraint_manuel' );

is ( find_type_constraint_manuel ( $FOO, 'vZoot' ), 		undef,		'find_type_constraint_manuel' );
is ( find_type_constraint_manuel ( $FOO, 'vStringId' ),	'Frost::StringId',	'find_type_constraint_manuel' );

throws_ok	{ check_type_constraint_manuel ( undef, undef, undef )	}	qr/Param class_or_obj missing/,	'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Qaz', undef, undef )	}	qr/Param name missing/,				'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Foo', undef, undef )	}	qr/Param name missing/,				'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( undef, undef, 42 )		}	qr/Param class_or_obj missing/,	'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Qaz', undef, 42 )		}	qr/Param name missing/,				'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Foo', undef, 42 )		}	qr/Param name missing/,				'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( 'Qaz', 'vZoot',		undef )	}	qr/Could not find a type constraint/,	'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Qaz', 'vStringId',	undef )	}	qr/Could not find a type constraint/,	'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( 'Foo', 'vZoot',		undef )	}	qr/Could not find a type constraint/,	'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( 'Foo', 'vStringId',	undef )	}	qr/does not pass the type constraint/,	'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( 'Foo', 'vStringId',	42 )		}	qr/does not pass the type constraint/,	'check_type_constraint_manuel';
lives_ok		{ check_type_constraint_manuel ( 'Foo', 'vStringId',	'FOO' )	}	'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( $FOO, 'vZoot',			undef )	}	qr/Could not find a type constraint/,	'check_type_constraint_manuel';

throws_ok	{ check_type_constraint_manuel ( $FOO, 'vStringId',	undef )	}	qr/does not pass the type constraint/,	'check_type_constraint_manuel';
throws_ok	{ check_type_constraint_manuel ( $FOO, 'vStringId',	42 )		}	qr/does not pass the type constraint/,	'check_type_constraint_manuel';
lives_ok		{ check_type_constraint_manuel ( $FOO, 'vStringId',	'FOO' )	}	'check_type_constraint_manuel';
