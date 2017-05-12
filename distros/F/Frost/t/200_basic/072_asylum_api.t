#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 84;
#use Test::More 'no_plan';

use Frost::Asylum;

#	Here Asylum acts like an object factory - no Foo->new used!

{
	package Foo;

	use Frost;

	has num	=> ( is => 'rw', isa => 'Int', required => 1 );		#	just in case...

	no Frost;

	__PACKAGE__->meta->make_immutable	( debug => 0 );
}

my $MAX_ID	= 5;
my $REST		= 0;

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	throws_ok	{ $ASYL->silence () }
		qr/Param class missing/,												'Error: silence w/o param';

	throws_ok	{ $ASYL->silence ( 'Bar' ) }
		qr/Can\'t locate object method "new" via package "Bar"/,		'Error: silence with unknown class';

	throws_ok	{ $ASYL->silence ( 'Foo' ) }
		qr/Attribute \(id\) is required/,									'Error: silence w/o id';

	throws_ok	{ $ASYL->silence ( 'Foo', 1 ) }
		qr/Attribute \(num\) is required/,									'Error: silence w/o num';

	#	We're not dead, test is still running, so let's clean up:
	#
	lives_ok	{ $ASYL->remove;	}												'Asylum removed';

	throws_ok	{ $ASYL->evoke () }
		qr/Param class missing at/,											'Error: evoke w/o param';

	throws_ok	{ $ASYL->evoke ( 'Foo' ) }
		qr/Param id missing/,													'Error: evoke w/o id';

	throws_ok	{ $ASYL->evoke ( 'Foo', 1 ) }
		qr/Can not evoke un-silenced Foo->1/,								'Error: evoke w/o silence';

	#	We're not dead, test is still running, so let's clean up:
	#
	lives_ok	{ $ASYL->remove;	}												'Asylum removed';

	throws_ok	{ $ASYL->absolve () }
		qr/Param class missing at/,											'Error: absolve w/o param';

	throws_ok	{ $ASYL->absolve ( 'Foo' ) }
		qr/Param id missing/,													'Error: absolve w/o id';

	throws_ok	{ $ASYL->absolve ( 'Foo', 1 ) }
		qr/Can not absolve un-evoked Foo->1/,								'Error: absolve w/o evoke';

	#	We're not dead, test is still running, so let's clean up:
	#
	lives_ok	{ $ASYL->remove;	}												'Asylum removed';

	throws_ok	{ $ASYL->excommunicate () }
		qr/Param class missing at/,											'Error: excommunicate w/o param';

	throws_ok	{ $ASYL->excommunicate ( 'Foo' ) }
		qr/Param id missing/,													'Error: excommunicate w/o id';

	throws_ok	{ $ASYL->excommunicate ( 'Foo', 1 ) }
		qr/Can not excommunicate un-absolved Foo->1/,					'Error: excommunicate w/o absolve';

	#	We're not dead, test is still running, so let's clean up:
	#
	lives_ok	{ $ASYL->remove;	}												'Asylum removed';
}

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	for ( 1..$MAX_ID )
	{
		my $foo;

		lives_ok	{ $foo	= $ASYL->silence ( 'Foo', $_, num => $_ * 1000 );	}	"silenced $_";

		isa_ok	$foo,	'Foo',						'$foo';
		isa_ok	$foo,	'Frost::Locum',	'$foo';
		isa_ok	$foo,	'Moose::Object',			'$foo';

		is $foo->num, $_ * 1000, "got the right foo->num for $_";
	}

	is $ASYL->count ( 'Foo' ),		0,					"no spirits buried";
	is $ASYL->twilight_count,			$MAX_ID,			"$MAX_ID spirits in twilight";

	lives_ok	{ $ASYL->close; }	'Asylum closed and saved';

	is $ASYL->count ( 'Foo' ),		$MAX_ID,			'all spirits absolved now';
	is $ASYL->twilight_count,			0,					'no spirits in twilight anymore';
}

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	is $ASYL->count ( 'Foo' ),		$MAX_ID,			"all spirits buried";
	is $ASYL->twilight_count,			0,					"no spirits in twilight";

	$REST	= $MAX_ID;

	for ( 1..$MAX_ID )
	{
		if ( $_ % 2 )
		{
			#	To be excommunicated, a spirit does not need to be evoked - as in real life ;-)
			lives_ok	{ $ASYL->excommunicate ( 'Foo', $_ ); }	"excommunicated the odd spirit $_";

			$REST--;
		}
		else
		{
			#	To be absolved, a spirit must to be evoked - as in real life, too ;-)
			lives_ok	{ $ASYL->evoke ( 'Foo', $_ ); }				"evoked the even spirit $_";
			lives_ok	{ $ASYL->absolve ( 'Foo', $_ ); }			"absolved the even spirit $_";
		}
	}

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits buried still";
	is $ASYL->twilight_count,			$REST,			"$REST in twilight still";

	lives_ok	{ $ASYL->close; }	'Asylum closed and saved';

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits absolved now";
	is $ASYL->twilight_count,			0,					'no spirits in twilight anymore';
}

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits buried";

	$REST	= 0;

	for ( 1..$MAX_ID )
	{
		if ( $_ % 2 )
		{
			isnt	$ASYL->exists ( 'Foo', $_ ), true,	"spirit $_ burns in hell";
		}
		else
		{
			my $foo;

			lives_ok	{ $foo	= $ASYL->evoke ( 'Foo', $_ );	}	"evoked spirit $_";

			isa_ok	$foo,	'Foo',						'$foo';
			isa_ok	$foo,	'Frost::Locum',	'$foo';
			isa_ok	$foo,	'Moose::Object',			'$foo';

			is $foo->num, $_ * 1000, "got the right foo->num for $_";

			$REST++;
		}
	}

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits absolved now";
	is $ASYL->twilight_count,			$REST,			"$REST spirits in twilight now";

	lives_ok	{ $ASYL->close; }	'Asylum closed and saved';

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits absolved now";
	is $ASYL->twilight_count,			0,					'no spirits in twilight anymore';
}
