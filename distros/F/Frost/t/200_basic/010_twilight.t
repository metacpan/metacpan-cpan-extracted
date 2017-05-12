#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 48;
#use Test::More 'no_plan';

use_ok 'Frost::Twilight';

{
	package Frost::Asylum;

	use Moose;

	has cachesize		=> ( isa => 'Int',	is => 'ro',	default => 1024 * 1024,	);

	#	just for type check and Twilight construction...
}

my $asylum	= Frost::Asylum->new();

my $twilight;

lives_ok { $twilight = Frost::Twilight->new ( asylum => $asylum ); }	'new twilight';

isa_ok	$twilight,	'Frost::Twilight',	'twilight';
isa_ok	$twilight,	'Moose::Object',		'twilight';

isa_ok	$twilight->_spirit,	'HASH',		'twilight->_spirit';

my $default_maxcount	= int ( ( 20_000 / DEFAULT_CACHESIZE() ) * $asylum->cachesize );

is $twilight->_maxcount,		$default_maxcount, 	"got the right default twilight_maxcount $default_maxcount";

isnt		$twilight->exists ( 'Foo', 42 ),		true,		'spirit does not exist';
is			$twilight->get ( 'Foo', 42 ),			undef,	'spirit is undef';

{
	my $spirit	=
	{
		id		=> 42,
		foo	=> 'foo',
	};

	is			$twilight->set ( 'Foo', 42, $spirit ),	$spirit,		'spirit is set';
	is			$twilight->exists ( 'Foo', 42 ),			true,			'spirit exists';
	is			$twilight->get ( 'Foo', 42 ),				$spirit,		'spirit is in the twilight zone';

	cmp_deeply	[ $spirit ],		[ $twilight->get ( 'Foo', 42 ) ],	'got correct spirit';
}

{
	my $spirit	=
	{
		id		=> 42,
		foo	=> 'foo',
		bar	=> 666,
	};

	lives_ok { $twilight->get ( 'Foo', 42 )->{bar} = 666; }	'set bar';

	cmp_deeply	[ $spirit ],		[ $twilight->get ( 'Foo', 42 ) ],	'got extended spirit';
}

{
	foreach my $val ( 1 .. 3 )
	{
		my $foo_spirit	= { id => 'foo' . $val, foo => $val, };
		my $bar_spirit	= { id => 'bar' . $val, bar => $val, };

		my $foo_id	= $foo_spirit->{id};
		my $bar_id	= $bar_spirit->{id};

		lives_ok { $twilight->set ( 'Foo', $foo_id, $foo_spirit ); }	"set spirit $foo_id of Foo";
		lives_ok { $twilight->set ( 'Bar', $bar_id, $bar_spirit ); }	"set spirit $bar_id of Bar";
	}
}

{
	foreach my $val ( 1 .. 3 )
	{
		my $foo_spirit	= { id => 'foo' . $val, foo => $val, };
		my $bar_spirit	= { id => 'bar' . $val, bar => $val, };

		my $foo_id	= $foo_spirit->{id};
		my $bar_id	= $bar_spirit->{id};

		is			$twilight->exists ( 'Foo', $foo_id ),			true,			"spirit $foo_id of Foo exists";
		is			$twilight->exists ( 'Bar', $bar_id ),			true,			"spirit $bar_id of Bar exists";

		cmp_deeply	[ $foo_spirit ],	[ $twilight->get ( 'Foo', $foo_id ) ],	'got correct spirit of Foo';
		cmp_deeply	[ $bar_spirit ],	[ $twilight->get ( 'Bar', $bar_id ) ],	'got correct spirit of Bar';
	}
}

{
	my $foo;

	my $spirit	=
	{
		id		=> 42,
		foo	=> 'foo',
		bar	=> 666,
	};

	my $id	= $spirit->{id};

	lives_ok	{ $foo = $twilight->del ( 'Foo', $id ); }	"spirit $id is removed from the twilight zone";

	cmp_deeply	[ $foo ],	[ $spirit ],	'removed the correct spirit of Foo';

	isnt		$twilight->exists ( 'Foo', $id ),		true,		'spirit does not exist anymore';
	is			$twilight->get ( 'Foo', $id ),			undef,	'spirit is undef';
}

IS_DEBUG and DEBUG Dumper $twilight;

$twilight->clear();

IS_DEBUG and DEBUG Dumper $twilight;

{
	foreach my $val ( 1..3 )
	{
		my $foo_id	= 'foo' . $val;
		my $bar_id	= 'bar' . $val;

		isnt			$twilight->exists ( 'Foo', $foo_id ),			true,			"spirit $foo_id of Foo has gone";
		isnt			$twilight->exists ( 'Bar', $bar_id ),			true,			"spirit $bar_id of Bar has gone";
	}
}

IS_DEBUG and DEBUG Dumper $twilight;

my $cpx_id;

{
	my $spirit	=
	{
		id		=> 'complex1',
		s		=> 'foo',
		a		=> [ ( 1..3 ) ],
		h		=> { map { $_ => 'h' . $_ } ( 1..3 ) },
		aa		=> [ [ ( 1..2 ) ], [ ( 3..4 ) ] ],
		hh		=> { 1 => { 2 => 'two' }, 3 => { 4 => 'four' } },
	};

	$cpx_id	= $spirit->{id};

	is			$twilight->set ( 'Foo', $cpx_id, $spirit ),	$spirit,		'complex spirit is set';
	is			$twilight->exists ( 'Foo', $cpx_id ),			true,			'complex spirit exists';
	is			$twilight->get ( 'Foo', $cpx_id ),				$spirit,		'complex spirit is in the twilight zone';

	cmp_deeply	[ $spirit ],		[ $twilight->get ( 'Foo', $cpx_id ) ],	'got correct complex spirit';
}

{
	my $spirit;

	lives_ok	{ $spirit = $twilight->get ( 'Foo', $cpx_id ); }	"got complex spirit";

	$spirit->{hh}->{666} = { 5 => 'five' };
}

{
	my $spirit	=
	{
		id		=> $cpx_id,
		s		=> 'foo',
		a		=> [ ( 1..3 ) ],
		h		=> { map { $_ => 'h' . $_ } ( 1..3 ) },
		aa		=> [ [ ( 1..2 ) ], [ ( 3..4 ) ] ],
		hh		=> { 1 => { 2 => 'two' }, 3 => { 4 => 'four' }, 666 => { 5 => 'five' } },
	};

	cmp_deeply	[ $spirit ],		[ $twilight->get ( 'Foo', $cpx_id ) ],	'got correct extended complex spirit';
}

IS_DEBUG and DEBUG Dumper $twilight;

