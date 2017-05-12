#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 45;

use_ok 'Frost::Asylum';

Frost::TestPath::make ( $TMP_PATH_1 );	#	must exist before creating of lock object!
Frost::TestPath::make ( $TMP_PATH_2 );	#	must exist before creating of lock object!

our $ASYL;
our $ASYL_OEM;

lives_ok		{ $ASYL =
					Frost::Asylum->new
					(
						data_root	=> $TMP_PATH,
					)
				}	'Asylum constructed';

lives_ok		{ $ASYL_OEM =
					Frost::Asylum->new
					(
						data_root	=> $TMP_PATH_1,
						lock		=> Frost::Lock->new
										(
											lock_rw			=> false,
											lock_wait		=> 5,
											lock_sleep		=> 0.5,
											lock_filename	=> make_file_path ( $TMP_PATH_1, '.mylock' ),
										),
					)
				}	'Asylum with own lock constructed';


isa ( $ASYL->_lock,		'Frost::Lock' );
isa ( $ASYL_OEM->_lock,	'Frost::Lock' );

#	these are private attributes...
#
is $ASYL->_lock->_lock_rw,				true,		'default is RW';
is $ASYL_OEM->_lock->_lock_rw,		false,	'oem     is RO';

is $ASYL->_lock->_lock_wait,			30,		'default is 30 sec';
is $ASYL_OEM->_lock->_lock_wait,		5,			'oem     is  5 sec';

is $ASYL->_lock->_lock_sleep,			0.2,		'default is 0.2 sec';
is $ASYL_OEM->_lock->_lock_sleep,	0.5,		'oem     is 0.1 sec';
#
###################################

isnt $ASYL->is_locked,		true,		'default is not locked';
isnt $ASYL_OEM->is_locked,	true,		'oem     is not locked';

is $ASYL->lock, 				true,		'default locked';
is $ASYL_OEM->lock, 			true,		'oem     locked';

is $ASYL->is_locked,			true,		'default is locked';
is $ASYL_OEM->is_locked,	true,		'oem     is locked';

is $ASYL->lock, 				true,		'default re-locking ok';
is $ASYL_OEM->lock, 			true,		'oem     re-locking ok';

is $ASYL->unlock, 			true,		'default unlocked';
is $ASYL_OEM->unlock, 		true,		'oem     unlocked';

isnt $ASYL->is_locked,		true,		'default is unlocked';
isnt $ASYL_OEM->is_locked,	true,		'oem     is unlocked';

is $ASYL->unlock, 			true,		'default re-unlocking ok';
is $ASYL_OEM->unlock, 		true,		'oem     re-unlocking ok';

is $ASYL->open, 				true,		'default opened';
is $ASYL_OEM->open, 			true,		'oem     opened';

is $ASYL->is_locked,			true,		'default is locked';
is $ASYL_OEM->is_locked,	true,		'oem     is locked';

is $ASYL->open, 				true,		'default re-open ok';
is $ASYL_OEM->open, 			true,		'oem     re-open ok';

is $ASYL->close,	 			true,		'default closed';
is $ASYL_OEM->close, 		true,		'oem     closed';

isnt $ASYL->is_locked,		true,		'default is unlocked';
isnt $ASYL_OEM->is_locked,	true,		'oem     is unlocked';

is $ASYL->close,	 			true,		'default re-closing ok';
is $ASYL_OEM->close, 		true,		'oem     re-closing ok';

#	Here are dragons...
#
my $lock_object;

{
	{
		my $local_asyl;

		lives_ok  { $local_asyl = Frost::Asylum->new ( data_root => $TMP_PATH_2, ) } 'Local asylum constructed';

		$lock_object	= $local_asyl->_lock;		#	DON'T TRY THIS AT HOME

		is $local_asyl->open, 			true,		'Local asylum opened';

		is $local_asyl->is_locked,		true,		'Local asylum is locked';
	}

	is $lock_object->is_locked,		true,		'Local object still locked (outside scope without Asylum->close)';

	is $lock_object->unlock,			true,		'Local object unlocked';

	{
		my $local_asyl;

		lives_ok  { $local_asyl = Frost::Asylum->new ( data_root => $TMP_PATH_2, ) } 'Local asylum constructed again';

		is $local_asyl->open, 			true,		'Local asylum opened';

		is $local_asyl->is_locked,		true,		'Local asylum is locked again';

		is $local_asyl->close,			true,		'Local asylum closed';
	}

	isnt $lock_object->is_locked,		true,		'Local object is unlocked (outside scope WITH Asylum->close)';
}
