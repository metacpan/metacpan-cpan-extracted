#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 46;
#use Test::More 'no_plan';

use_ok 'Frost::Asylum';

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

	has id		=> ( 						isa => 'Int',	is => 'ro' );
	has _dirty	=> ( virtual	=> 1,	isa => 'Bool',	is => 'ro' );

	has mul	=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check
	has uni	=> ( index => 'unique',	is => 'rw', isa => 'Str' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

our $KB	= 1024;
our $MB	= $KB * $KB;

my $sizes	=
{
	1	=> { size => DEFAULT_CACHESIZE,			count => 20_000,	display => ( DEFAULT_CACHESIZE / $MB ), },
	2	=> { size => DEFAULT_CACHESIZE / 8,		count => 2_500,	display => ( ( DEFAULT_CACHESIZE / 8 ) / $MB ), },
	3	=> { size => DEFAULT_CACHESIZE * 2.5,	count => 50_000,	display => ( ( DEFAULT_CACHESIZE * 2.5 ) / $MB ), },
};

foreach my $key ( sort keys %$sizes )
{
	my ( $asylum );

	if ( $key == 1 )
	{
		lives_ok
		{
			$asylum = Frost::Asylum->new
			(
				classname	=> 'Foo',
				data_root	=> $TMP_PATH,
			);
		}
		'NEW ASYLUM DEFAULT ' . $sizes->{$key}->{display} . ' MB';
	}
	else
	{
		lives_ok
		{
			$asylum = Frost::Asylum->new
			(
				classname	=> 'Foo',
				data_root	=> $TMP_PATH,
				cachesize	=> $sizes->{$key}->{size},
			);
		}
		'REOPEN ASYLUM WITH ' . $sizes->{$key}->{display} . ' MB';
	}

	#	trigger creation of twilight, cemeteries and illuminators
	#
	$asylum->lookup ( 'Foo', 42,	'id'	);
	$asylum->lookup ( 'Foo', 42,	'mul'	);
	$asylum->lookup ( 'Foo', 42,	'uni'	);

	is $asylum->cachesize,	$sizes->{$key}->{size},		'asylum->cachesize '	. $sizes->{$key}->{display} . ' MB';
	is $asylum->twilight_maxcount,	$sizes->{$key}->{count},	'asylum->twilight_maxcount '	. $sizes->{$key}->{count} . ' spirits';

	# DON'T TRY THIS AT HOME, these are private properties...
	#
	is $asylum->_twilight->maxcount, $sizes->{$key}->{count}, 'twilight->maxcount ' . $sizes->{$key}->{count} . ' spirits';

	is $asylum->_necromancer->cachesize, $sizes->{$key}->{size}, 'necromancer->cachesize';

	is $asylum->_necromancer->_mortician('Foo')->cachesize, $sizes->{$key}->{size}, 'mortician->cachesize';

	while ( my ( $slot, $cemetery ) = each %{ $asylum->_necromancer->_mortician('Foo')->_cemetery() || {} } )
	{
		is $cemetery->cachesize, $sizes->{$key}->{size}, 'cemetery->cachesize (' . $slot . ')';
	}

	while ( my ( $slot, $illuminator ) = each %{ $asylum->_necromancer->_mortician('Foo')->_illuminator() || {} } )
	{
		is $illuminator->cachesize, $sizes->{$key}->{size}, 'illuminator->cachesize (' . $slot . ')';
	}
	#
	##########################################################

	lives_ok { $asylum->twilight_maxcount ( 1000 ) } 'can change twilight_maxcount';
	is $asylum->twilight_maxcount, 1000, 'asylum->twilight_maxcount 1000 spirits';

	throws_ok { $asylum->cachesize ( 666 ) }	qr/Cannot assign a value to a read-only accessor/,	'can NOT change cachesize';

	lives_ok { $asylum->close; }	'ASYLUM CLOSED';
}

