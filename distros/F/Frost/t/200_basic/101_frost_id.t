#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More tests => 43;
use Test::More 'no_plan';

use Moose::Util::TypeConstraints;
use Frost::Types;

use Frost::Asylum;

subtype 'XNum'
	=> as 'Num',
	=> where { $_ > 100 };

subtype 'XStr'
	=> as 'Str',
	=> where { $_ gt 'AAA' };

subtype 'XNumStr'
	=> as 'Str | Num',
	=> where { $_ gt '0' };

subtype 'XNatural'
	=> as 'Frost::Natural',
	=> where { $_ > 200 };

subtype 'XStringId'
	=> as 'Frost::StringId',
	=> where { $_ =~ m/^[A-Z][A-Z][A-Z]$/};

subtype 'XBSN'
	=> as 'Frost::BSN | XStringId';

subtype 'XUniqueStringId'
	=> as 'Frost::UniqueStringId',
	=> where { $_ =~ m/^[0-9]+-[0-9]+-[0-9]+-[0-9]+-[0-9]+$/ };

subtype 'XEmailString'
	=> as 'Frost::EmailString',
	=> where { $_ =~ /example\.com$/ };

subtype 'XUniqueId'
	=> as 'Frost::UniqueId | Frost::Date';

subtype 'UniqueDate'
	=> as 'Frost::Date';

subtype 'CoerceDate'
	=> as 'UniqueDate';

coerce 'CoerceDate'
	=> from 'SqlDate'
	=> via { $_->ymd() };

{
	package SqlDate;

	use Moose;

	has year		=> ( is => 'rw', isa => 'Frost::Natural' );
	has month	=> ( is => 'rw', isa => 'Frost::Natural' );
	has day		=> ( is => 'rw', isa => 'Frost::Natural' );

	sub ymd		{ sprintf ( "%04d-%02d-%02d", $_[0]->year, $_[0]->month, $_[0]->day ); }
}

my $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH );

my $types	=
[
	qw(
		XNum XStr XNumStr
		Frost::Natural	Frost::StringId		Frost::BSN		Frost::UniqueStringId		Frost::EmailString		Frost::UniqueId
		XNatural	XStringId	XBSN		XUniqueStringId	XEmailString	XUniqueId
		UniqueDate CoerceDate
	)
];

my $ids	=
{
	XNum							=> { good => 101,					bad => 100				},
	XStr							=> { good => 'AAB',				bad => 'AA'				},
	XNumStr						=> { good => 1,					bad => ''				},
	'Frost::Natural'			=> { good => 1,					bad => 0					},
	'Frost::StringId'			=> { good => 'A42',				bad => '42A'			},
	'Frost::BSN'				=> { good => '01A05-2',			bad => '01A05_2'		},
	'Frost::UniqueStringId'	=> { good => UUID,				bad => 'X-Y-Z-4-5'	},
	'Frost::EmailString'		=> { good => 'x@y.zzz',			bad => 'Ä@Ö.ÜÜ'		},
	'Frost::UniqueId'			=> { good => 42,					bad => -42				},
	XNatural						=> { good => 201,					bad => 200				},
	XStringId					=> { good => 'ABC',				bad => 'abc'			},
	XBSN							=> { good => 'ABC',				bad => 'abc'			},
	XUniqueStringId			=> { good => '1-2-3-4-5',		bad => 'A-B-C-D-E'	},
	XEmailString				=> { good => 'x@example.com',	bad => 'x@test.com'	},
	XUniqueId					=> { good => '2009-07-11',		bad => '42A'			},
	UniqueDate					=> { good => '2009-12-01',		bad => '09-12-01'		},
	CoerceDate					=> {
											good		=> SqlDate->new ( year => 2009, month => 5, day => 8 ),
											bad		=> bless ( {}, 'Bar' ),
											coerce	=> 1,
										},
};

foreach my $constraint ( @$types )
{
	my ( $pack, $class, $foo );

	my $coerce	= $ids->{$constraint}->{coerce} || 0;

	$pack	=<<"EOT";
{
	package Foo::$constraint;

	use Frost;

#	::lives_ok { has id	=> ( isa => '$constraint', coerce => 1 ); }			'Foo::$constraint defined id';
	::lives_ok { has id	=> ( isa => '$constraint', coerce => $coerce ); }			'Foo::$constraint defined id';

	no Frost;

	if ( \$::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable	( debug => 0 );	}
	else							{ __PACKAGE__->meta->make_immutable	( debug => 0 );	}
}
EOT

	eval $pack;

	$class	= "Foo::$constraint";

	#DEBUG $pack, "\n";

	lives_ok		{ $foo = $class->new ( id => $ids->{$constraint}->{good}, asylum => $ASYL ); }
		"success $constraint with $ids->{$constraint}->{good}";

	#DEBUG Dumper $ASYL, $foo;

	throws_ok	{ $foo = $class->new ( id => $ids->{$constraint}->{bad}, asylum => $ASYL ); }
		qr/Attribute \(id\) does not pass the type constraint/,
		"failed  $constraint with $ids->{$constraint}->{bad}";

	$pack	=<<"EOT";
{
	package Foo::Inherited::$constraint;

	use Frost;

#	::lives_ok { has '+id'	=> ( isa => '$constraint', coerce => 1 ); }		'Foo::Inherited::$constraint defined +id';
	::lives_ok { has '+id'	=> ( isa => '$constraint', coerce => $coerce ); }			'Foo::$constraint defined id';

	no Frost;

	if ( \$::MAKE_MUTABLE )	{ __PACKAGE__->meta->make_mutable	( debug => 0 );	}
	else							{ __PACKAGE__->meta->make_immutable	( debug => 0 );	}
}
EOT

	eval $pack;

	$class	= "Foo::Inherited::$constraint";

	#DEBUG $pack, "\n";

	lives_ok		{ $foo = $class->new ( id => $ids->{$constraint}->{good}, asylum => $ASYL ); }
		"success $constraint with $ids->{$constraint}->{good}";

	#DEBUG Dumper $ASYL, $foo;

	throws_ok	{ $foo = $class->new ( id => $ids->{$constraint}->{bad}, asylum => $ASYL ); }
		qr/Attribute \(id\) does not pass the type constraint/,
		"failed  $constraint with $ids->{$constraint}->{bad}";
}
