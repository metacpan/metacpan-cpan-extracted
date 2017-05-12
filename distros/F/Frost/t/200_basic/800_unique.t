#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 10;

{
	package Foo;
	use Frost;
	use Frost::Util;

	has foo		=> ( index => true,		isa => 'Str' );
	has bar		=> ( index => 'unique',	isa => 'Str' );

	no Frost;

	__PACKAGE__->meta->make_immutable();
}

use Frost::Asylum;

my $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH );

my $data	=
[
	{ id => 'id1', foo => 'foo1', bar => 'bar1' },
	{ id => 'id2', foo => 'foo2', bar => 'bar2' },
	{ id => 'id3', foo => 'foo3', bar => 'bar3' },
	{ id => 'id4', foo => 'foo3', bar => 'bar2' },
	{ id => 'id5', foo => 'foo1', bar => 'bar3' },
];

my $results	=
{
	foo1	=> [qw( id1 id5 )],
	foo2	=> [qw( id2 )],
	foo3	=> [qw( id3 id4 )],
	bar1	=> [qw( id1 )],
	bar2	=> [qw( id4 )],
	bar3	=> [qw( id5 )],
};

{
	foreach my $rec ( @$data )
	{
		Foo->new ( %$rec, asylum => $asylum );
	}
}

$asylum->close();

{
	foreach my $rec ( @$data )
	{
		my @param		= ( 'Foo', $rec->{foo}, 'foo' );
		my @found		= ();

		my $id			= $asylum->first ( @param );		# class, key, attribute_name

		while ( $id )
		{
			push @found, $id;

			$id	= $asylum->next ( @param );
		}

		my @expected	= @{ $results->{$rec->{foo}} };

		cmp_deeply	\@found, bag ( @expected ),	"find foo='$rec->{foo}' (@expected)";
	}
}

{
	foreach my $rec ( @$data )
	{
		my @param		= ( 'Foo', $rec->{bar}, 'bar' );
		my @found		= ();

		my $id			= $asylum->first ( @param );		# class, key, attribute_name

		while ( $id )
		{
			push @found, $id;

			$id	= $asylum->next ( @param );
		}

		my @expected	= @{ $results->{$rec->{bar}} };

		cmp_deeply	\@found, bag ( @expected ),	"find bar='$rec->{bar}' (@expected)";
	}
}

