#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More tests => 42;
use Test::More 'no_plan';

use Frost::Asylum;

#	Testing Twilight::LRU::_cull -> Twilight::_cull_callback -> Asylum::_absolve

{
	package Foo;

	use Frost;

	has num	=> ( is => 'rw', isa => 'Int' );

	no Frost;

	__PACKAGE__->meta->make_immutable	( debug => 0 );
}

my $MAX_ID		= 7;
my $MAX_COUNT	= 5;
my $REST_COUNT	= $MAX_ID - $MAX_COUNT;

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	#	see Frost::Twilight::_build__maxcount
	#
	my $default_maxcount	= int ( ( 20_000 / DEFAULT_CACHESIZE() ) * $ASYL->cachesize );

	is $ASYL->twilight_maxcount,		$default_maxcount, 	"got the right default twilight_maxcount $default_maxcount";

	lives_ok	{ $ASYL->twilight_maxcount ( $MAX_COUNT ); }	"set Twilight twilight_maxcount to $MAX_COUNT";

	is $ASYL->twilight_maxcount,				$MAX_COUNT, 	"got the right twilight_maxcount $MAX_COUNT";

	for ( 1..$MAX_ID )
	{
		my $foo	= Foo->new ( id => $_, asylum => $ASYL, num => $_ * 1000 );
	}

	is $ASYL->count ( 'Foo' ),		$REST_COUNT,	"$REST_COUNT spirits absolved";
	is $ASYL->twilight_count,		$MAX_COUNT,		"$MAX_COUNT spirits still in twilight";

	lives_ok	{ $ASYL->close; }	'Asylum closed and saved';

	is $ASYL->count ( 'Foo' ),		$MAX_ID,			'all spirits absolved now';
	is $ASYL->twilight_count,		0,					'no spirits in twilight anymore';
}

{
	my $ASYL;

	lives_ok	{ $ASYL	= Frost::Asylum->new ( data_root => $TMP_PATH ); }	'Asylum created';

	lives_ok	{ $ASYL->twilight_maxcount ( $MAX_COUNT ); }	"set Twilight twilight_maxcount to $MAX_COUNT";

	is $ASYL->count ( 'Foo' ),		$MAX_ID,			"all spirits buried";

	for ( 1..$MAX_ID )
	{
		my $foo	= Foo->new ( id => $_, asylum => $ASYL );

		is $foo->num, $_ * 1000, "got the right foo->num for $_";
	}

	is $ASYL->count ( 'Foo' ),		$MAX_ID,			"all spirits evoked";
	is $ASYL->twilight_count,		$MAX_COUNT,		"$MAX_COUNT spirits in twilight now";
}
