#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 240;
#use Test::More 'no_plan';

use_ok 'Frost::Mortician';

{
	package Qee;			#	must exist for type ClassName

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

	has id		=> ( 							is => 'rw', isa => 'Int' );	#	must exist for attribute check
	has qee_num	=> ( index => 'unique',	is => 'rw', isa => 'Int' );	#	must exist for attribute check, creates illuminator
	has qee_str	=> ( index => 1,			is => 'rw', isa => 'Str' );	#	must exist for attribute check, creates illuminator

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
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
			attribute			=> [ 'Frost::Meta::Attribute' ],
		}
	);

	has id		=> ( 							is => 'rw', isa => 'Int' );	#	must exist for attribute check
	has foo_num	=> ( index => 'unique',	is => 'rw', isa => 'Int' );	#	must exist for attribute check, creates illuminator
	has foo_str	=> ( index => 1,			is => 'rw', isa => 'Str' );	#	must exist for attribute check, creates illuminator

	has s		=> ( is => 'rw', isa => 'Str' );			#	must exist for attribute check
	has a		=> ( is => 'rw', isa => 'ArrayRef' );	#	must exist for attribute check
	has h		=> ( is => 'rw', isa => 'HashRef' );	#	must exist for attribute check
	has aa	=> ( is => 'rw', isa => 'ArrayRef' );	#	must exist for attribute check
	has hh	=> ( is => 'rw', isa => 'HashRef' );	#	must exist for attribute check
	has c		=> ( is => 'rw', isa => 'Qee' );			#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $data		=
{
	id			=> 42,
	foo_num	=> 666,
	foo_str	=> 'eternal',
	s			=> 'foo',
	a			=> [ ( 1..3 ) ],
	h			=> { map { $_ => 'h' . $_ } ( 1..3 ) },
	aa			=> [ [ ( 1..2 ) ], [ ( 3..4 ) ] ],
	hh			=> { 1 => { 2 => 'two' }, 3 => { 4 => 'four' } },
	c			=> Qee->new ( id => 99 ),
};

my $id		= $data->{id};

#	This is a simplified version!!!
#
my $spirit	=
{
	id			=> $data->{id},
	foo_num	=> $data->{foo_num},
	foo_str	=> $data->{foo_str},
	s			=> $data->{s},
	a			=> $data->{a},
	h			=> $data->{h},
	aa			=> $data->{aa},
	hh			=> $data->{hh},
	c			=> { CLASS_TYPE()	=> { TYPE_ATTR() => ref ( $data->{c} ), REF_ATTR() => $data->{c}->{id}	}	},		#	!!!
};

my @order	= qw( id foo_num foo_str s a h aa hh c );

my $db_file		= {};
my $ndx_file	= {};

foreach my $key ( keys %$spirit )
{
	$db_file->{$key}	= make_file_path $TMP_PATH, 'Foo', $key . '.cem';
	$ndx_file->{$key}	= make_file_path $TMP_PATH, 'Foo', $key . '.ill';
}

#IS_DEBUG and DEBUG Dump [ $data, $spirit, $db_file, $ndx_file ], [qw( data spirit db_file ndx_file )];

sub check_db_file ( $ )
{
	my $test	= shift;

	foreach my $key ( @order )
	{
		if ( $test->{$key} )
		{
			ok		-e $db_file->{$key},	"$db_file->{$key} exists";
		}
		else
		{
			ok	!	-e $db_file->{$key},	"$db_file->{$key} missing";
		}
	}
}

sub check_ndx_file ( $ )
{
	my $test	= shift;

	foreach my $key ( @order )
	{
		next	unless $key =~ /^(foo_num|foo_str)$/;

		if ( $test->{$key} )
		{
			ok		-e $ndx_file->{$key},	"$ndx_file->{$key} exists";
		}
		else
		{
			ok	!	-e $ndx_file->{$key},	"$ndx_file->{$key} missing";
		}
	}
}

my $regex;

{
	$regex	= qr/Attribute \((data_root|classname)\) is required/;

	throws_ok	{ my $mortician = Frost::Mortician->new; }
		$regex,	'Mortician->new';

	throws_ok	{ my $mortician = Frost::Mortician->new(); }
		$regex,	'Mortician->new()';

	throws_ok	{ my $mortician = Frost::Mortician->new ( classname => 'Foo' ); }
		$regex,	'Param data_root missing';

	throws_ok	{ my $mortician = Frost::Mortician->new ( data_root => $TMP_PATH_NIX ); }
		$regex,	'Param classname missing';

	throws_ok	{ my $mortician = Frost::Mortician->new ( data_root => $TMP_PATH ); }
		$regex,	'Param classname missing';

#	$regex	= qr/Attribute \(classname\) does not pass the type constraint .* 'ClassName' failed .* Bar/;
#	Moose 1.05:
	$regex	= qr/Attribute \(classname\) does not pass the type constraint .* 'ClassName' .* Bar/;

	throws_ok	{ my $mortician = Frost::Mortician->new ( classname => 'Bar', data_root => $TMP_PATH ); }
		$regex,	'Bad classname';

#	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' failed .* $TMP_PATH_NIX/;
#	Moose 1.05:
	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' .* $TMP_PATH_NIX/;

	throws_ok	{ my $mortician = Frost::Mortician->new ( classname => 'Foo', data_root => $TMP_PATH_NIX ); }
		$regex,	'Bad data_root';
}

my $mortician;

lives_ok { $mortician = Frost::Mortician->new ( classname => 'Foo', data_root => $TMP_PATH ); }
	'new mortician';

check_db_file	{};
check_ndx_file	{};

is		$mortician->classname,	'Foo',					'mortician->classname';
is		$mortician->data_root,	$TMP_PATH,				'mortician->data_root';
is		$mortician->cachesize,	DEFAULT_CACHESIZE,	'mortician->cachesize';

{
	my ( $cemetery, $illuminator );

	lives_ok	{ $cemetery		= $mortician->_cemetery();		}	'mortician->_cemetery';
	lives_ok	{ $illuminator	= $mortician->_illuminator();	}	'mortician->_illuminator';

	isa_ok	$cemetery,		'HASH',	'mortician->_cemetery';
	isa_ok	$illuminator,	'HASH',	'mortician->_illuminator';

	check_db_file	{};
	check_ndx_file	{};

	isnt		$mortician->exists ( $id ),					true,		'spirit id does not exist';

	check_db_file	{ id => 1 };
	check_ndx_file	{};

	isnt		$mortician->exists ( $id, 'foo_num' ),		true,		'spirit foo_num does not exist';
	isnt		$mortician->exists ( $id, 'foo_str' ),		true,		'spirit foo_str does not exist';

	check_db_file	{ map { $_ => 1} qw( id foo_num foo_str ) };
	check_ndx_file	{};

	$cemetery	= $mortician->_cemetery->{'id'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'mortician->_cemetery->id';

	is			$cemetery->numeric,		true,						'cemetery->id sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->id holds unique keys';
	is			$cemetery->filename,		$db_file->{id},		"cemetery->id buries in $db_file->{id}";

	$cemetery	= $mortician->_cemetery->{'foo_num'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'mortician->_cemetery->foo_num';

	is			$cemetery->numeric,		true,						'cemetery->foo_num sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->foo_num holds unique keys';
	is			$cemetery->filename,		$db_file->{foo_num},	"cemetery->foo_num buries in $db_file->{foo_num}";

	$cemetery	= $mortician->_cemetery->{'foo_str'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'mortician->_cemetery->foo_str';

	is			$cemetery->numeric,		true,						'cemetery->foo_str sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->foo_str holds unique keys';
	is			$cemetery->filename,		$db_file->{foo_str},	"cemetery->foo_str buries in $db_file->{foo_str}";
}

lives_ok		{ $mortician->save; }	'mortician->save (flush buffers)';

{
	my $db_checks	= { map { $_ => 1 } qw( id foo_num foo_str ) };	#	we have touched this!
	my $ndx_checks	= {};

	foreach my $slot ( @order )
	{
		is		$mortician->bury ( $id, $slot, $spirit->{$slot} ),	true,		"bury $slot";

		$db_checks->{$slot}++;
		$ndx_checks->{$slot}++;

		check_db_file	$db_checks;
		check_ndx_file	$ndx_checks;
	}
}

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $mortician->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_open,				true,		"cemetery $slot is open"; }

		my $illuminator	= $mortician->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_open,			true,		"illuminator $slot is open"; }
	}
}

lives_ok		{ $mortician->leisure; }	'mortician->leisure (america drinks and goes home)';

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $mortician->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_closed,			true,		"cemetery $slot is closed"; }

		my $illuminator	= $mortician->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_closed,		true,		"illuminator $slot is closed"; }
	}
}

{
	my $exp_spirit	= {};
	my $exp_data	= {};

	foreach my $slot ( @order )
	{
		my $slot_spirit;

		lives_ok	{ $slot_spirit	= $mortician->grub ( $id, $slot ) }		"grub $slot";		#	auto-re-open...

		$exp_spirit->{$slot}	= $slot_spirit;

		#	This is a simplified version!!!
		#
		if	( ref ( $slot_spirit ) eq 'HASH' and $slot_spirit->{CLASS_TYPE()} )
		{
			my $value				= $slot_spirit->{CLASS_TYPE()};

			$exp_data->{$slot}	= $value->{type}->new ( id => $value->{ref} );
		}
		else
		{
			my $value				= $slot_spirit;

			$exp_data->{$slot}	= $value;
		}
	}

	cmp_deeply	[ $exp_spirit	],	[ $spirit	],	'got same spirit';
	cmp_deeply	[ $exp_data		],	[ $data		],	'got same data';
}

lives_ok		{ $mortician->leisure; }	'mortician->leisure again';

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $mortician->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_closed,			true,		"cemetery $slot is closed"; }

		my $illuminator	= $mortician->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_closed,		true,		"illuminator $slot is closed"; }
	}
}

{
	my $id;
	my $exp_id;

	lives_ok	{ $id	= $mortician->lookup ( 42 ) }								'lookup 42, id';		#	auto-re-open...
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],	'got id';

	lives_ok	{ $id	= $mortician->lookup ( 666 ) }								'lookup 666, id';
	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],	'got no id';

	lives_ok	{ $id	= $mortician->lookup ( 666, 'foo_num'  ) }				'lookup 666, foo_num';
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],	'got id';

	lives_ok	{ $id	= $mortician->lookup ( 666, 'foo_str'  ) }				'lookup 666, foo_str';
	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],	'got no id';

#	See Burial::_numeric_compare / _validate_key
#	We will never use Mortician stand-alone, so all checks are removed !
#
#	lives_ok	{ $id	= $mortician->lookup ( 'eternal' ) }						"lookup 'eternal', id";
#	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],	'got no id';
#
#	lives_ok	{ $id	= $mortician->lookup ( 'eternal', 'foo_num' ) }		"lookup 'eternal', foo_num";
#	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],	'got no id';
#
########################################

	lives_ok	{ $id	= $mortician->lookup ( 'eternal', 'foo_str'  ) }		"lookup 'eternal', foo_str";
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],	'got id';
}

#	find...

#IS_DEBUG and DEBUG 'DONE', Dumper $mortician;
