#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 136;
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
			class					=> [ 'Frost::Meta::Class'		],
			attribute			=> [ 'Frost::Meta::Attribute' ],
		}
	);

	has id			=> (						isa => 'Str',			is => 'ro' );
#	has real_class	=> ( transient	=> 1,	isa => 'ClassName',	is => 'ro',	init_arg => undef,	default => 'Qee' );
	has _dirty		=> ( virtual	=> 1,	isa => 'Bool',			is => 'ro' );

	sub isa { $_[1] =~ /^(Qee|Frost::Locum)$/ }		#	this is a lie...

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Foo;

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

	has foo_num	=> ( index => 'unique',	is => 'rw', isa => 'Int' );
	has foo_str	=> ( index => 1,			is => 'rw', isa => 'Str' );

	has s		=> ( is => 'rw', isa => 'Str' );
	has a		=> ( is => 'rw', isa => 'ArrayRef' );
	has h		=> ( is => 'rw', isa => 'HashRef' );
	has aa	=> ( is => 'rw', isa => 'ArrayRef' );
	has ah	=> ( is => 'rw', isa => 'ArrayRef' );
	has hh	=> ( is => 'rw', isa => 'HashRef' );
	has ha	=> ( is => 'rw', isa => 'HashRef' );
	has c		=> ( is => 'rw', isa => 'Qee' );

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $regex;

{
	$regex	= qr/Attribute \((data_root)\) is required/;

	throws_ok	{ my $asylum = Frost::Asylum->new; }
		$regex,	'Asylum->new';

	throws_ok	{ my $asylum = Frost::Asylum->new(); }
		$regex,	'Asylum->new()';

#	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' failed .* $TMP_PATH_NIX/;
#	Moose 1.05:
	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' .* $TMP_PATH_NIX/;

	throws_ok	{ my $asylum = Frost::Asylum->new ( data_root => $TMP_PATH_NIX ); }
		$regex,	'Bad data_root';
}

my $asylum;

lives_ok	{ $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'asylum created';

isnt		$asylum->is_locked,		true,	'asylum is NOT locked';

lives_ok	{ $asylum->lock; }		'asylum locked';
is			$asylum->is_locked,		true,	'asylum is locked';
lives_ok	{ $asylum->unlock; }		'asylum unlocked';

isnt		$asylum->is_locked,		true,	'asylum is NOT locked';

lives_ok	{ $asylum->open; }		'asylum opened';
is			$asylum->is_locked,		true,	'asylum is locked';
lives_ok	{ $asylum->close; }		'asylum closed';					#	save works as well...

isnt		$asylum->is_locked,		true,	'asylum is NOT locked';

lives_ok { $asylum->open }			'asylum opened';
is			$asylum->is_locked,		true,	'asylum is locked';
lives_ok { $asylum->open }			're-open asylum ok';
lives_ok	{ $asylum->lock; }		're-lock asylum ok';
lives_ok { $asylum->close }		'asylum closed';

isnt		$asylum->is_locked,		true,	'asylum is NOT locked';

lives_ok { $asylum->close }		're-close asylum ok';
lives_ok { $asylum->unlock }		're-unlock asylum ok';

#	OEM locking see t/300_lock/510_lock.t

#	DON'T TRY THIS AT HOME,
#	use only the API methods below...
#
#	The following stuff will be done by Frost::Locum magi-, automati- and what-ever-cally!
#
my $data	=
{
	id			=> 42,
	foo_num	=> 666,
	foo_str	=> 'eternal',
	s			=> 'foo',
	a			=> [ ( 1..3 ) ],
	h			=> { map { $_ => 'h' . $_ } ( 1..3 ) },
	aa			=> [ [ ( 1..2 ) ], [ ( 3..4 ) ] ],
	ah			=> [ { 11 => 'eleven' }, { 12 => 'twelve' }, ],
	ha			=> { 7 => [ ( 70..72 ) ], 8 => [ ( 80..82 ) ] },
	hh			=> { 1 => { 2 => 'two' }, 3 => { 4 => 'four' } },
	c			=> Qee->new ( id => 'THIS_IS_THE_ID_OF_QEE' ),
};

my $data_2	=
{
	id			=> 142,
	foo_num	=> 777,
	foo_str	=> 'eternal',
};

my $data_3	=
{
	id			=> 242,
	foo_num	=> 888,
	foo_str	=> 'eternal',
};

my $id		= $data->{id};
my $id_q		= $data->{c}->id;

my $id_2		= $data_2->{id};
my $id_3		= $data_3->{id};

#	prepare test...
#
is		$asylum->_silence ( 'Qee', $id_q, 'id', $id_q ),		true,		"_silence Qee id";
is		$asylum->_silence ( 'Qee', $id_q, '_dirty', true ),	true,		"_silence Qee _dirty manually";

foreach my $slot ( keys %$data )
{
	is		$asylum->_silence ( 'Foo', $id, $slot, $data->{$slot} ),	true,		"_silence Foo $id $slot";		#	auto-create of id-spirit
}
is		$asylum->_silence ( 'Foo', $id, '_dirty', true ),	true,		"_silence Foo $id _dirty manually";

foreach my $slot ( keys %$data_2 )
{
	is		$asylum->_silence ( 'Foo', $id_2, $slot, $data_2->{$slot} ),	true,		"_silence Foo $id_2 $slot";
}
is		$asylum->_silence ( 'Foo', $id_2, '_dirty', true ),	true,		"_silence Foo $id_2 _dirty manually";

foreach my $slot ( keys %$data_3 )
{
	is		$asylum->_silence ( 'Foo', $id_3, $slot, $data_3->{$slot} ),	true,		"_silence Foo $id_3 $slot";
}
is		$asylum->_silence ( 'Foo', $id_3, '_dirty', true ),	true,		"_silence Foo $id_3 _dirty manually";

lives_ok	{ $asylum->close; }		'asylum saved and closed';

$asylum	= undef;		#	force auto-open and -reload

lives_ok	{ $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'asylum re-created';

#	API methods:
#
throws_ok	{ $asylum->exists; }					qr/Param class missing/,	'exists - class missing';
throws_ok	{ $asylum->exists(); }				qr/Param class missing/,	'exists - class missing';
throws_ok	{ $asylum->exists ( 'Foo' ); }	qr/Param id missing/,		'exists - id missing';
throws_ok	{ $asylum->exists ( 'Qee' ); }	qr/Param id missing/,		'exists - id missing';
throws_ok	{ $asylum->exists ( 'Bar' ); }	qr/Param id missing/,		'exists - id missing';

is		$asylum->exists ( 'Foo', $id		),	true,		"Foo $id lives in asylum";
is		$asylum->exists ( 'Foo', $id_2	),	true,		"Foo $id_2 lives in asylum";
is		$asylum->exists ( 'Foo', $id_3	),	true,		"Foo $id_3 lives in asylum";
is		$asylum->exists ( 'Foo', $id_q	),	false,	"Foo $id_q lives NOT in asylum";
is		$asylum->exists ( 'Foo', 666 		),	false,	"Foo 666 lives NOT in asylum";

is		$asylum->exists ( 'Qee', $id		),	false,	"Qee $id lives NOT in asylum";
is		$asylum->exists ( 'Qee', $id_2	),	false,	"Qee $id_2 lives NOT in asylum";
is		$asylum->exists ( 'Qee', $id_3	),	false,	"Qee $id_3 lives NOTin asylum";
is		$asylum->exists ( 'Qee', $id_q	),	true,		"Qee $id_q lives in asylum";
is		$asylum->exists ( 'Qee', 666 		),	false,	"Qee 666 lives NOT in asylum";

is		$asylum->exists ( 'Bar', $id		),	false,	"Bar $id lives NOT in asylum";
is		$asylum->exists ( 'Bar', $id_2	),	false,	"Bar $id_2 lives NOT in asylum";
is		$asylum->exists ( 'Bar', $id_3	),	false,	"Bar $id_3 lives NOTin asylum";
is		$asylum->exists ( 'Bar', $id_q	),	false,	"Bar $id_q lives NOT in asylum";
is		$asylum->exists ( 'Bar', 666 		),	false,	"Bar 666 lives NOT in asylum";

throws_ok	{ $asylum->count; }					qr/Param class missing/,	'count - class missing';
throws_ok	{ $asylum->count(); }				qr/Param class missing/,	'count - class missing';

is		$asylum->count ( 'Foo'							),	3,	"count 3 Foo";						#	access cemetery(id)
is		$asylum->count ( 'Foo', undef					),	3,	"count 3 Foo undef";				#
is		$asylum->count ( 'Foo', undef, undef		),	3,	"count 3 Foo undef undef";		#
is		$asylum->count ( 'Foo', undef, 'id'			),	3,	"count 3 Foo undef id";			#

is		$asylum->count ( 'Foo', undef, 'foo_num'	),	3,	"count 3 Foo undef foo_num";	#	access cemetery(slot)
is		$asylum->count ( 'Foo', undef, 'foo_str'	),	3,	"count 3 Foo undef foo_str";	#
is		$asylum->count ( 'Foo', undef, 's'			),	1,	"count 1 Foo undef s";			#	1 !
is		$asylum->count ( 'Foo', undef, 'h'			),	1,	"count 1 Foo undef h";			#	1 !

is		$asylum->count ( 'Foo', $id		),	1,				"count 1 Foo $id";
is		$asylum->count ( 'Foo', $id_2		),	1,				"count 1 Foo $id_2";
is		$asylum->count ( 'Foo', $id_3		),	1,				"count 1 Foo $id_3";
is		$asylum->count ( 'Foo', $id_q		),	0,				"count 0 Foo $id_q";
is		$asylum->count ( 'Foo', 666		),	0,				"count 0 Foo 666";

is		$asylum->count ( 'Qee', $id_q		),	1,				"count 1 Qee $id_q";
is		$asylum->count ( 'Qee', 666		),	0,				"count 0 Qee 666";

is		$asylum->count ( 'Bar', $id		),	0,				"count 0 Bar $id";
is		$asylum->count ( 'Bar', 666		),	0,				"count 0 Bar 666";

foreach my $slot ( keys %$data )
{
	is		$asylum->count ( 'Foo', $id,		$slot ),	1,	"count 1 Foo $id $slot";
}

foreach my $slot ( keys %$data_2 )
{
	is		$asylum->count ( 'Foo', $id_2,	$slot ),	1,	"count 1 Foo $id_2 $slot";
}

foreach my $slot ( keys %$data_3 )
{
	is		$asylum->count ( 'Foo', $id_2,	$slot ),	1,	"count 1 Foo $id_3 $slot";
}

{
	my $lup_id;
	my $exp_id;

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo" ) }										"lookup";
	$exp_id	= undef;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got undef";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", undef ) }							"lookup undef";
	$exp_id	= undef;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got undef";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", undef, undef ) }					"lookup undef, undef";
	$exp_id	= undef;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got undef";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id ) }								"lookup $id";
	$exp_id	= $id;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id, undef ) }						"lookup $id, undef";
	$exp_id	= $id;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id, "id" ) }						"lookup $id, id";
	$exp_id	= $id;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id, "bar" ) }						"lookup $id, bar";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id, "foo_num" ) }				"lookup $id, foo_num";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", $id, "foo_str" ) }				"lookup $id, foo_str";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", 666 ) }								"lookup 666, id";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", 666, "foo_str"  ) }				"lookup 666, foo_str";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", 666, "foo_num"  ) }				"lookup 666, foo_num";
	$exp_id	= $id;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", 777, "foo_num" ) }				"lookup 777, foo_num";
	$exp_id	= $id_2;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id_2";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", 888, "foo_num" ) }				"lookup 888, foo_num";
	$exp_id	= $id_3;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id_3";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", "eternal" ) }						"lookup eternal, id";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", "eternal", "foo_num"  ) }		"lookup eternal, foo_num";
	$exp_id	= "";				cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got empty";

	lives_ok	{ $lup_id	= $asylum->lookup ( "Foo", "eternal", "foo_str"  ) }		"lookup eternal, foo_str";
	$exp_id	= $id;			cmp_deeply	[ $lup_id	],	[ $exp_id	],					"got $id";
}

