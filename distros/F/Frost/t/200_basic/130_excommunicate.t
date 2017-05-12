#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 36;
#use Test::More 'no_plan';

use Frost::Asylum;

{
	package Foo;

	use Frost;

	has num	=> ( is => 'rw', isa => 'Int' );

	no Frost;

	__PACKAGE__->meta->make_immutable	( debug => 0 );
}

my $MAX_ID	= 5;
my $REST		= 0;

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	for ( 1..$MAX_ID )
	{
		my $foo	= Foo->new ( id => $_, asylum => $ASYL, num => $_ * 1000 );

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
		next	unless $_ % 2;		#	only the straight will be absolved...

		lives_ok	{ $ASYL->excommunicate ( 'Foo', $_ ); }	"excommunicated the odd spirit $_";

		$REST--;
	}

	is $ASYL->count ( 'Foo' ),		$REST,			"$REST spirits buried still";
	is $ASYL->twilight_count,			0,					"no spirits in twilight still";

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

			lives_ok	{ $foo	= Foo->new ( id => $_, asylum => $ASYL );	}	"evoked spirit $_";

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
