#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 75;
#use Test::More 'no_plan';

BEGIN
{
	use_ok	'IO::File';
	use_ok	'Frost::Types';
	use_ok	'Frost::Util';
}

our $EXPECTED_ROOT_VERSION	= 0.5;

#######################

is		true,		1,			'true  is 1';
is		false,	0,			'false is 0';
is		TRUE,		'true',	'TRUE  is "true"';
is		FALSE,	'false',	'FALSE is "false"';

#######################

$Frost::Util::UUID_CLEAR	= true;
$Frost::Util::UUID_OBJ		= undef;		#	Don't try this at home!

my $u1	= UUID || 'ERROR 1';

is		$u1,												'A-A-A-A-1',	"UUID is $u1";
is		$Frost::Util::UUID_OBJ,		1,					'UUID_OBJ is 1';

$Frost::Util::UUID_CLEAR	= false;
$Frost::Util::UUID_OBJ		= undef;		#	Don't try this at home!

my $u2	= UUID || 'ERROR 2';

like		$u2,	'/^[0-9A-F]+-[0-9A-F]+-[0-9A-F]+-[0-9A-F]+-[0-9A-F]+$/',	"UUID is $u2";
isa_ok	$Frost::Util::UUID_OBJ,	'Data::UUID';

#######################

is		UUID_NEW_TAG,	'UNEW-UNEW-UNEW-UNEW-UNEW',	'UUID_NEW_TAG is UNEW-UNEW-UNEW-UNEW-UNEW';
is		UUID_BAD_TAG,	'UBAD-UBAD-UBAD-UBAD-UBAD',	'UUID_BAD_TAG is UBAD-UBAD-UBAD-UBAD-UBAD';

is		TIMESTAMP_ZERO,	'0000-00-00 00:00:00',	'TIMESTAMP_ZERO is 0000-00-00 00:00:00';

is		SORT_INT,	'int',	'SORT_INT   is int';
is		SORT_FLOAT,	'float',	'SORT_FLOAT is float';
is		SORT_DATE,	'date',	'SORT_DATE  is date';
is		SORT_TEXT,	'text',	'SORT_TEXT  is text';

is		STATUS_NOT_INITIALIZED,	'not_initialized',	'STATUS_NOT_INITIALIZED is not_initialized';
is		STATUS_MISSING,			'missing',				'STATUS_MISSING         is missing';
is		STATUS_EXISTS,				'exists',				'STATUS_EXISTS          is exists'			  ;
is		STATUS_LOADED,				'loaded',				'STATUS_LOADED          is loaded';

is		ROOT_VERSION,	$EXPECTED_ROOT_VERSION,
												"ROOT_VERSION is $EXPECTED_ROOT_VERSION";
is		ROOT_TAG,		'frost',			'ROOT_TAG     is frost';
is		OBJECT_TAG,		'object',		'OBJECT_TAG   is object';
is		ATTR_TAG,		'attr',			'ATTR_TAG     is attr';
is		VALUE_TAG,		'value',			'VALUE_TAG    is value';

is		ID_ATTR,			'id',				'ID_ATTR      is id';
is		NAME_ATTR,		'name',			'NAME_ATTR    is name';
is		TYPE_ATTR,		'type',			'TYPE_ATTR    is type';
is		REF_ATTR,		'ref',			'REF_ATTR     is ref';

is		VALUE_TYPE,		'__VALUE__',	'VALUE_TYPE   is __VALUE__';
is		ARRAY_TYPE,		'__ARRAY__',	'ARRAY_TYPE   is __ARRAY__';
is		HASH_TYPE,		'__HASH__',		'HASH_TYPE    is __HASH__';
is		CLASS_TYPE,		'__CLASS__',	'CLASS_TYPE   is __CLASS__';

#######################

#	Inlined for speed
#
#	is				make_cache_key ( 'A', 'B' ),		'A|B',	'make_cache_key returns A|B';
#	cmp_deeply	[ split_cache_key ( 'A|B' ) ],	[ 'A', 'B' ],	'split_cache_key returns ( A, B )';

#######################

diag <<'EOT';

find_attribute_manuel...         see 100_meta/010_types.t
find_type_constraint_manuel...   see 100_meta/010_types.t
check_type_constraint_manuel...  see 100_meta/010_types.t
EOT

#######################

is		make_path		( qw( A B C ) ),			'/A/B/C/',	'make_path       A   B   C  => /A/B/C/';
is		make_path		( qw( /A /B /C ) ),		'/A/B/C/',	'make_path      /A  /B  /C  => /A/B/C/';
is		make_path		( qw( /A/ /B/ /C/ ) ),	'/A/B/C/',	'make_path      /A/ /B/ /C/ => /A/B/C/';
is		make_file_path	( qw( A B C ) ),			'/A/B/C',	'make_file_path  A   B   C  => /A/B/C';
is		make_file_path	( qw( /A /B /C ) ),		'/A/B/C',	'make_file_path /A  /B  /C  => /A/B/C';
is		make_file_path	( qw( /A/ /B/ /C/ ) ),	'/A/B/C',	'make_file_path /A/ /B/ /C/ => /A/B/C';

#######################
{
	my $fp_in	= '//' . $TMP_PATH . '/A//B//';
	my $fp_out	= $TMP_PATH . '/A/B';

	is		check_or_create_dir ( $fp_in, true ),	$fp_out,	"check_or_create_dir $fp_out, not created";
	ok		! -e $fp_out, 												"$fp_out does not exist";

	is		check_or_create_dir ( $fp_in ),			$fp_out,	"check_or_create_dir $fp_out, created";

	ok		-e $fp_out, 												"$fp_out exists";
	ok		-d $fp_out, 												"$fp_out is directory";

	my (	$dev, $ino, $mode, $nlink, $uid, $gid, $rdev ,
			$size, $atime, $mtime, $ctime, $blksize, $blocks	)	= stat ( $fp_out );

	my $mode_in		= $mode & 07777;
	my $mode_out	= 0700;

	is		$mode_in,	$mode_out,	"$fp_out mode is 0700";

	BAIL_OUT ( "No write access to $fp_out" )		unless -e $fp_out;
}
	#######################
{
	my $class		= 'Foo::Bar';
	my $fp_class	= $TMP_PATH . '/Foo/Bar';

	is		filepath_from_class ( $TMP_PATH, $class, true ),	$fp_class,	"filepath_from_class $fp_class, not created";
	ok		! -e $fp_class, 																	"$fp_class does not exist";

	is		filepath_from_class ( $TMP_PATH, $class ),			$fp_class,	"filepath_from_class $fp_class, created";

	ok		-e $fp_class, 																	"$fp_class exists";
	ok		-d $fp_class, 																	"$fp_class is directory";

	my (	$dev, $ino, $mode, $nlink, $uid, $gid, $rdev ,
			$size, $atime, $mtime, $ctime, $blksize, $blocks	)	= stat ( $fp_class );

	my $mode_in		= $mode & 07777;
	my $mode_out	= 0700;

	is		$mode_in,	$mode_out,	"$fp_class mode is 0700";

	BAIL_OUT ( "No write access to $fp_class" )		unless -e $fp_class;
}
	#######################
{
	my $class		= 'Qaz::Poo';
	my $id			= 42;
	my $fp_class	= $TMP_PATH . '/Qaz/Poo';
	my $fp_out		= $TMP_PATH . '/Qaz/Poo/42.xml';

	is		filename_from_class_and_id ( $TMP_PATH, $class, $id, true ),	$fp_out,	"filename_from_class_and_id $fp_out, $fp_class not created";
	ok		! -e $fp_class, 																			"$fp_class does not exist";
	ok		! -e $fp_out, 																				"$fp_out does not exist";

	is		filename_from_class_and_id ( $TMP_PATH, $class, $id ),			$fp_out,	"filename_from_class_and_id $fp_out, $fp_class created";

	ok		-e $fp_class, 																				"$fp_class exists";
	ok		-d $fp_class, 																				"$fp_class is directory";
	ok		! -f $fp_out, 																				"$fp_out does not exist";

	my (	$dev, $ino, $mode, $nlink, $uid, $gid, $rdev ,
			$size, $atime, $mtime, $ctime, $blksize, $blocks	)	= stat ( $fp_class );

	my $mode_in		= $mode & 07777;
	my $mode_out	= 0700;

	is		$mode_in,	$mode_out,	"$fp_class mode is 0700";

	BAIL_OUT ( "No write access to $fp_class" )		unless -e $fp_class;
}
	#######################
{
	my $class		= 'Zick::Zack';
	my $id			= 4711;
	my $fp_class	= $TMP_PATH . '/Zick/Zack/4711.xml';

	my ( $c, $i );

	lives_ok	{ ( $c, $i ) = class_and_id_from_filename ( $TMP_PATH, $fp_class ) }		"class_and_id_from_filename $fp_class";
	is			$c,	$class,	"got $class";
	is			$i,	$id,		"got $id";
}

#######################

my ( $filename, $fh );

$filename	= make_file_path $TMP_PATH, '.Frost_lock';

lives_ok	{ touch ( $filename )		}	"$filename touched";
BAIL_OUT ( "No write access to $filename" )		unless -e $filename;

ok		-e $filename, 																	"$filename exists";
ok		-f $filename, 																	"$filename is file";

my (	$dev, $ino, $mode, $nlink, $uid, $gid, $rdev ,
		$size, $atime, $mtime, $ctime, $blksize, $blocks	)	= stat ( $filename );

my $mode_in		= $mode & 07777;
my $mode_out	= 0600;

is		$mode_in,	$mode_out,	"$filename mode is 0600";

$fh			= new IO::File $filename, O_RDONLY;
BAIL_OUT ( "Cannot read $filename" )		unless $fh;

is		lock_fh		( $fh ),	true,	"$filename locked";
is		unlock_fh	( $fh ),	true,	"$filename unlocked";

$fh->close;

is		lock_fh		( $fh ),	false,	"closed fh not locked";
is		unlock_fh	( $fh ),	false,	"closed fh not unlocked";

is		lock_fh		( undef ),	false,	"undef not locked";
is		unlock_fh	( undef ),	false,	"undef not unlocked";

#######################

diag <<'EOT';

exclusive/shared locks...        see 300_lock
EOT

#######################

ok	check_type_manuel ( 'Frost::FilePath', $filename ), 'check_type_manuel';

