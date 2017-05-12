#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More;

our $LEVEL;
our $MAX_ID;

BEGIN
{
	{
		my $circle_tests	= 20;
		my $level_tests	= 4;
		my $asylum_tests	= 8;

		$LEVEL	= 3;	#	min 1 == Circle

		$MAX_ID	= $LEVEL;

		my $tests	= $MAX_ID * 4;

		plan tests => $tests + $circle_tests + $level_tests + $asylum_tests;
	}
}

no warnings "recursion";

use Frost::Asylum;

#         +------+
#   +---->|      |-----+
#   |     |Circle|     |
#   +-----|      |<----+
#         +------+
#
#
#         +------+        +------+
#   +---->|      |------->|      |-----+
#   |     | Loop |        | Loop |     |
#   | +---|      |<-------|      |<--+ |
#   | |   +------+        +------+   | |
#   | |                              | |
#   | |   +------+        +------+   | |
#   | +-->|      |------->|      |---+ |
#   |     | Loop |        | Loop |     |
#   +-----|      |<-------|      |<----+
#         +------+        +------+
#
{
	package Circle;
	use Frost;
	use Frost::Util;

	has 'last'	=>
	(
		is				=> 'rw',
		isa			=> 'Circle',

		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	has 'next'	=>
	(
		is				=> 'rw',
		isa			=> 'Circle',

		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	sub add_next
	{
		#::IS_DEBUG and ::DEBUG "( @_ )";

		my ( $self, $next )	= @_;

		$next->last ( $self );
		$self->next ( $next );
	}

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Loop;
	use Moose;

	extends 'Circle';

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

diag '### Create circle ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $circ;

	lives_ok	{ $circ	= Circle->new ( asylum => $ASYL, id => 'CIRCLE' );	}	'CIRCLE created';

	ok		( $circ->_dirty,											'CIRCLE is dirty' );

	$circ->add_next ( $circ );

	is		( $circ->id,							'CIRCLE',		'got id level 0' );
	is		( $circ->next->id,					'CIRCLE',		'got id level 1' );
	is		( $circ->next->next->id,			'CIRCLE',		'got id level 2' );
	is		( $circ->next->next->next->id,	'CIRCLE',		'got id level 3' );

	is		( $circ->id,							'CIRCLE',		'got id level 0' );
	is		( $circ->last->id,					'CIRCLE',		'got id level -1' );
	is		( $circ->last->last->id,			'CIRCLE',		'got id level -2' );
	is		( $circ->last->last->last->id,	'CIRCLE',		'got id level -3' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Load circle ###';

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $circ;

	lives_ok	{ $circ	= Circle->new ( asylum => $ASYL, id => 'CIRCLE' );	}	'CIRCLE loaded';

	ok		( ! $circ->_dirty,											'CIRCLE is clean' );

	is		( $circ->id,							'CIRCLE',		'got id level 0' );
	is		( $circ->next->id,					'CIRCLE',		'got id level 1' );
	is		( $circ->next->next->id,			'CIRCLE',		'got id level 2' );
	is		( $circ->next->next->next->id,	'CIRCLE',		'got id level 3' );

	is		( $circ->id,							'CIRCLE',		'got id level 0' );
	is		( $circ->last->id,					'CIRCLE',		'got id level -1' );
	is		( $circ->last->last->id,			'CIRCLE',		'got id level -2' );
	is		( $circ->last->last->last->id,	'CIRCLE',		'got id level -3' );

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag '### Create loop ###';

our $ID			= 1;

diag "### About to create and store $MAX_ID loop(s)...";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $loop	= Loop->new ( asylum => $ASYL, id => "LOOP_$ID" );

	ok		( $loop->_dirty,											'LOOP is dirty' );

	my $last	= $loop;

	foreach ( 1 .. ( $LEVEL - 1 ) )
	{
		$ID++;

		my $next	= Loop->new ( asylum => $ASYL, id => "LOOP_$ID" );

		$last->add_next ( $next );

		$last	= $next;
	}

	$last->add_next ( $loop );

	my $curr	= $loop;

	foreach my $id ( 1 .. $ID )
	{
		is		( $curr->id,	"LOOP_$id",		"got id LOOP_$id (next)" );

		$curr	= $curr->next;
	}

	is		( $curr->id,		"LOOP_1",		"got id LOOP_1" );

	$curr	= $curr->last;

	foreach my $id ( reverse ( 1 .. $ID ) )
	{
		is		( $curr->id,	"LOOP_$id",		"got id LOOP_$id (last)" );

		$curr	= $curr->last;
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

diag "### $ID of $MAX_ID Loop(s) created and stored ###";

diag "### Load loop ###";

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $loop	= Loop->new ( asylum => $ASYL, id => "LOOP_1" );

	ok		( ! $loop->_dirty,											'LOOP is clean' );

	my $curr	= $loop;

	foreach my $id ( 1 .. $ID )
	{
		is		( $curr->id,	"LOOP_$id",		"got id LOOP_$id (next)" );

		$curr	= $curr->next;
	}

	is		( $curr->id,		"LOOP_1",		"got id LOOP_1" );

	$curr	= $curr->last;

	foreach my $id ( reverse ( 1 .. $ID ) )
	{
		is		( $curr->id,	"LOOP_$id",		"got id LOOP_$id (last)" );

		$curr	= $curr->last;
	}

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
