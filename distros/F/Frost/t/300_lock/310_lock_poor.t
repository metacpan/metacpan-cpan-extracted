#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 25;

use_ok 'Frost::Asylum';

Frost::TestPath::make ( $TMP_PATH_2 );	#	must exist before creating of lock object!

#	This test shows the ability of Asylum to work with
#	a new lock class, that extends Frost::Lock...
#
{
	package PoorMansLock;

	#	THIS IS A VERY BAD IDEA...

	use Moose;
	extends 'Frost::Lock';	#	for type constraint...

	use Frost::Types;
	use Frost::Util;

	sub is_locked
	{
		my ( $self )	= @_;

		return ( -e $self->_lock_filename ? true : false );
	}

	sub lock
	{
		my ( $self )	= @_;

		return true								if -e $self->_lock_filename;

		touch $self->_lock_filename;

		return $self->is_locked;
	}

	sub unlock
	{
		my ( $self )	= @_;

		unlink $_[0]->_lock_filename		if -e $_[0]->_lock_filename;

		return not $self->is_locked;
	}

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

our $ASYL;

lives_ok		{ $ASYL =
					Frost::Asylum->new
					(
						data_root	=> $TMP_PATH,
						lock			=> PoorMansLock->new ( lock_filename => make_file_path ( $TMP_PATH, 'poor.lock' ) ),
					)
				}	'Asylum with poor lock constructed';


isa ( $ASYL->_lock,		'Frost::Lock' );

isnt $ASYL->is_locked,		true,		'Asylum is not locked';

is $ASYL->lock, 				true,		'Asylum locked';
is $ASYL->is_locked,			true,		'Asylum is locked';
is $ASYL->lock, 				true,		'Asylum re-locking ok';

is $ASYL->unlock, 			true,		'Asylum unlocked';
isnt $ASYL->is_locked,		true,		'Asylum is unlocked';

is $ASYL->unlock, 			true,		'Asylum re-unlocking ok';

is $ASYL->open, 				true,		'Asylum opened';
is $ASYL->is_locked,			true,		'Asylum is locked';
is $ASYL->open, 				true,		'Asylum re-open ok';

is $ASYL->close,	 			true,		'Asylum closed';
isnt $ASYL->is_locked,		true,		'Asylum is unlocked';

is $ASYL->close,	 			true,		'Asylum re-closing ok';

#	Here are dragons...
#
my $lock_object;

{
	{
		my $local_asyl;

		lives_ok		{ $local_asyl =
							Frost::Asylum->new
							(
								data_root	=> $TMP_PATH_2,
								lock			=> PoorMansLock->new ( lock_filename => make_file_path ( $TMP_PATH_2, 'poor.lock' ) ),
							)
						}	'Local asylum with poor lock constructed';

		$lock_object	= $local_asyl->_lock;		#	DON'T TRY THIS AT HOME

		is $local_asyl->open, 			true,		'Local asylum opened';

		is $local_asyl->is_locked,		true,		'Local asylum is locked';
	}

	is $lock_object->is_locked,		true,		'Local object still locked (outside scope without Asylum->close)';

	is $lock_object->unlock,			true,		'Local object unlocked';

	{
		my $local_asyl;

		lives_ok		{ $local_asyl =
							Frost::Asylum->new
							(
								data_root	=> $TMP_PATH_2,
								lock			=> PoorMansLock->new ( lock_filename => make_file_path ( $TMP_PATH_2, 'poor.lock' ) ),
							)
						}	'Local asylum with poor lock constructed';

		is $local_asyl->open, 			true,		'Local asylum opened';

		is $local_asyl->is_locked,		true,		'Local asylum is locked again';

		is $local_asyl->close,			true,		'Local asylum closed';
	}

	isnt $lock_object->is_locked,		true,		'Local object is unlocked (outside scope WITH Asylum->close)';
}
