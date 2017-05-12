#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 9;

#	+---------+     +---------+
#	|         |---->|         |
#	| Loop(1) |		 | Loop(2) |
#	|         |<----|         |
#	+---------+		 +---------+


{
	package Loop;
	use Frost;
	use Frost::Util;

	has content	=> ( is => 'rw', isa => 'Str' );

	has 'last'	=>
	(
		is				=> 'rw',
		isa			=> 'Loop',
		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	has 'next'	=>
	(
		is				=> 'rw',
		isa			=> 'Loop',
		weak_ref		=> false,		#	weak refs are VERBOTEN
	);

	sub add_next
	{
		my ( $self, $next )	= @_;

		$next->last ( $self );
		$self->next ( $next );
	}

	no Frost;

	__PACKAGE__->meta->make_immutable();
}

use Frost::Asylum;

my $asylum	= Frost::Asylum->new ( data_root => $TMP_PATH );

my $loop1	= Loop->new ( asylum => $asylum, id => 1, content => 'This is Loop 1' );
my $loop2	= Loop->new ( asylum => $asylum, id => 2, content => 'This is Loop 2' );

$loop1->add_next ( $loop2 );
$loop2->add_next ( $loop1 );

IS_DEBUG and DEBUG Dump [ $loop1, $loop2, $asylum ], [qw( loop1 loop2 asylum )];

{
	my $loop1n2	= $loop1->next();
	my $loop1l2	= $loop1->last();

	my $loop2n1	= $loop2->next();
	my $loop2l1	= $loop2->last();

	IS_DEBUG and DEBUG Dump [ $loop1n2, $loop1l2, $loop2n1, $loop2l1, $asylum ], [qw( loop1n2 loop1l2 loop2n1 loop2l1 asylum )];

	isnt	$loop1n2,	$loop2,	'got different references 2 N 1';
	isnt	$loop1l2,	$loop2,	'got different references 2 L 1';
	isnt	$loop2n1,	$loop1,	'got different references 1 N 2';
	isnt	$loop2l1,	$loop1,	'got different references 1 L 2';
}

my $loop3	= Loop->new ( asylum => $asylum, id => 3, content => 'This is Loop 3');

$loop3->add_next ( $loop2 );
$loop1->add_next ( $loop3 );

IS_DEBUG and DEBUG Dump [ $loop3, $asylum ], [qw( loop3 asylum )];

$asylum->save();

IS_DEBUG and DEBUG Dump [ $asylum ], [qw( asylum )];

$asylum->close();

IS_DEBUG and DEBUG Dump [ $asylum ], [qw( asylum )];

#   ===>   next
#   --->   last
#
#   +---------+     +---------+     +---------+
#   |         |====>|         |====>|         |
#   |         |<----|         |<----|         |
#   | Loop(1) |     | Loop(3) |     | Loop(2) |
#   |         |     |         |     |         |
#   |         |     |         |     |         |
#   |         |     |         |     |         |
#   |         |     |         |     |         |
#   |         |     +---------+     |         |
#   |         |-------------------->|         |
#   |         |<====================|         |
#   +---------+                     +---------+

{
	my $loop3 = Loop->new ( id => 3, asylum => $asylum );

	is		$loop3->content,					'This is Loop 3',	'got correct content 3';

	is		$loop3->last->content,			'This is Loop 1',	'got correct content 1';
	is		$loop3->next->content,			'This is Loop 2',	'got correct content 2';
	is		$loop3->next->next->content,	'This is Loop 1',	'got correct content 1';
	is		$loop3->last->next->content,	'This is Loop 3',	'got correct content 3';
}
