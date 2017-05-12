#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 235;
#use Test::More 'no_plan';

use_ok 'Frost::Necromancer';

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
	$regex	= qr/Attribute \(data_root\) is required/;

	throws_ok	{ my $necromancer = Frost::Necromancer->new; }
		$regex,	'Necromancer->new';

	throws_ok	{ my $necromancer = Frost::Necromancer->new(); }
		$regex,	'Necromancer->new()';

#	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' failed .* $TMP_PATH_NIX/;
#	Moose 1.05:
	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' .* $TMP_PATH_NIX/;

	throws_ok	{ my $necromancer = Frost::Necromancer->new ( data_root => $TMP_PATH_NIX ); }
		$regex,	'Param classname missing';
}

my $necromancer;

lives_ok { $necromancer = Frost::Necromancer->new ( classname => 'Foo', data_root => $TMP_PATH ); }
	'new necromancer';

check_db_file	{};
check_ndx_file	{};

is		$necromancer->data_root,	$TMP_PATH,				'necromancer->data_root';
is		$necromancer->cachesize,	DEFAULT_CACHESIZE,	'necromancer->cachesize';

{
	my ( $cemetery, $illuminator );

	lives_ok	{ $cemetery		= $necromancer->_mortician('Foo')->_cemetery();		}	'necromancer->_cemetery';
	lives_ok	{ $illuminator	= $necromancer->_mortician('Foo')->_illuminator();	}	'necromancer->_illuminator';

	isa_ok	$cemetery,		'HASH',	'necromancer->_cemetery';
	isa_ok	$illuminator,	'HASH',	'necromancer->_illuminator';

	check_db_file	{};
	check_ndx_file	{};

	isnt		$necromancer->exists ( 'Foo', $id ),					true,		'spirit id does not exist';

	check_db_file	{ id => 1 };
	check_ndx_file	{};

	isnt		$necromancer->exists ( 'Foo', $id, 'foo_num' ),		true,		'spirit foo_num does not exist';
	isnt		$necromancer->exists ( 'Foo', $id, 'foo_str' ),		true,		'spirit foo_str does not exist';

	check_db_file	{ map { $_ => 1} qw( id foo_num foo_str ) };
	check_ndx_file	{};

	$cemetery	= $necromancer->_mortician('Foo')->_cemetery->{'id'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'necromancer->_cemetery->id';

	is			$cemetery->numeric,		true,						'cemetery->id sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->id holds unique keys';
	is			$cemetery->filename,		$db_file->{id},		"cemetery->id buries in $db_file->{id}";

	$cemetery	= $necromancer->_mortician('Foo')->_cemetery->{'foo_num'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'necromancer->_cemetery->foo_num';

	is			$cemetery->numeric,		true,						'cemetery->foo_num sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->foo_num holds unique keys';
	is			$cemetery->filename,		$db_file->{foo_num},	"cemetery->foo_num buries in $db_file->{foo_num}";

	$cemetery	= $necromancer->_mortician('Foo')->_cemetery->{'foo_str'};
	isa_ok	$cemetery,	'Frost::Cemetery',	'necromancer->_cemetery->foo_str';

	is			$cemetery->numeric,		true,						'cemetery->foo_str sorts numeric ids';
	is			$cemetery->unique,		true,						'cemetery->foo_str holds unique keys';
	is			$cemetery->filename,		$db_file->{foo_str},	"cemetery->foo_str buries in $db_file->{foo_str}";
}

lives_ok		{ $necromancer->save; }	'necromancer->save (flush buffers)';

{
	my $db_checks	= { map { $_ => 1 } qw( id foo_num foo_str ) };	#	we have touched this!
	my $ndx_checks	= {};

	foreach my $slot ( @order )
	{
		is		$necromancer->silence ( 'Foo', $id, $slot, $spirit->{$slot} ),	true,		"silence $slot";

		$db_checks->{$slot}++;
		$ndx_checks->{$slot}++;

		check_db_file	$db_checks;
		check_ndx_file	$ndx_checks;
	}
}

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $necromancer->_mortician('Foo')->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_open,				true,		"cemetery $slot is open"; }

		my $illuminator	= $necromancer->_mortician('Foo')->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_open,			true,		"illuminator $slot is open"; }
	}
}

lives_ok		{ $necromancer->leisure; }	'necromancer->leisure (america drinks and goes home)';

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $necromancer->_mortician('Foo')->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_closed,			true,		"cemetery $slot is closed"; }

		my $illuminator	= $necromancer->_mortician('Foo')->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_closed,		true,		"illuminator $slot is closed"; }
	}
}

{
	my $exp_spirit	= {};
	my $exp_data	= {};

	foreach my $slot ( @order )
	{
		my $slot_spirit;

		lives_ok	{ $slot_spirit	= $necromancer->evoke ( 'Foo', $id, $slot ) }		"evoke $slot";		#	auto-re-open...

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

lives_ok		{ $necromancer->leisure; }	'necromancer->leisure again';

{
	foreach my $slot ( @order )
	{
		my $cemetery		= $necromancer->_mortician('Foo')->_cemetery()->{$slot};

		if ( $cemetery )		{ is		$cemetery->is_closed,			true,		"cemetery $slot is closed"; }

		my $illuminator	= $necromancer->_mortician('Foo')->_illuminator()->{$slot};

		if ( $illuminator )	{ is		$illuminator->is_closed,		true,		"illuminator $slot is closed"; }
	}
}

{
	my $id;
	my $exp_id;

	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 42 ) }							'lookup 42, id';		#	auto-re-open...
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],			'got id';

	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 666 ) }							'lookup 666, id';
	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],			'got no id';

	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 666, 'foo_num'  ) }			'lookup 666, foo_num';
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],			'got id';

	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 666, 'foo_str'  ) }			'lookup 666, foo_str';
	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],			'got no id';

#	See Burial::_numeric_compare / _validate_key
#	We will never use Necromancer stand-alone, so all checks are removed !
#
#	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 'eternal' ) }					"lookup 'eternal', id";
#	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],			'got no id';
#
#	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 'eternal', 'foo_num' ) }	"lookup 'eternal', foo_num";
#	$exp_id	= '';						cmp_deeply	[ $exp_id	],	[ $id	],			'got no id';
#
########################################

	lives_ok	{ $id	= $necromancer->lookup ( 'Foo', 'eternal', 'foo_str'  ) }	"lookup 'eternal', foo_str";
	$exp_id	= 42;						cmp_deeply	[ $exp_id	],	[ $id	],			'got id';
}

IS_DEBUG and DEBUG 'DONE', Dumper $necromancer;
