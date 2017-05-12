#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 47;
#use Test::More 'no_plan';

use_ok 'Frost::Illuminator';

{
	package Foo;			#	must exist for type ClassName

	#	Just testing - DON'T TRY THIS AT HOME!
	#	Always say "use Frost"...
	#
	use Moose;

	Moose::Util::MetaRole::apply_metaroles
	(
		for						=> __PACKAGE__,
		class_metaroles		=>
		{
			attribute			=> [ 'Frost::Meta::Attribute' ],
		}
	);

	has foo_num	=> ( index => 1,			is => 'rw', isa => 'Int' );		#	must exist for attribute check
	has foo_str	=> ( index => 1,			is => 'rw', isa => 'Str' );		#	must exist for attribute check
	has uni_str	=> ( index => 'unique',	is => 'rw', isa => 'Str' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

is		Frost::Illuminator->suffix(),	'.ill',	'suffix is .ill';

my $regex;

{
	$regex	= qr/Attribute \((data_root|classname|slotname)\) is required/;

	throws_ok	{ my $illuminator = Frost::Illuminator->new; }
		$regex,	'Illuminator->new';

	throws_ok	{ my $illuminator = Frost::Illuminator->new(); }
		$regex,	'Illuminator->new()';

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( classname => 'Foo' ); }
		$regex,	'Param data_root and slotname missing';

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( slotname => 'foo_num' ); }
		$regex,	'Param data_root and classname missing';

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( slotname => 'foo_str' ); }
		$regex,	'Param data_root and classname missing';

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_num' ); }
		$regex,	'Param data_root missing';

	$regex	= qr/Class 'Bar' has no attribute 'foo_num'/;

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( classname => 'Bar', slotname => 'foo_num', data_root => $TMP_PATH ); }
		$regex,	'Bad slotname in Bar';

	$regex	= qr/Class 'Foo' has no attribute 'bar'/;

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( classname => 'Foo', slotname => 'bar', data_root => $TMP_PATH ); }
		$regex,	'Bad slotname in Foo';

#	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' failed .* $TMP_PATH_NIX/;
#	Moose 1.05:
	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' .* $TMP_PATH_NIX/;

	throws_ok	{ my $illuminator = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH_NIX ); }
		$regex,	'Bad data_root';
}

my $filename_num	= make_file_path $TMP_PATH, 'Foo', 'foo_num.ill';
my $filename_str	= make_file_path $TMP_PATH, 'Foo', 'foo_str.ill';
my $filename_uni	= make_file_path $TMP_PATH, 'Foo', 'uni_str.ill';

{
	my ( $illuminator_num, $illuminator_str, $illuminator_uni );

	lives_ok { $illuminator_num = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		'new illuminator_num';
	lives_ok { $illuminator_str = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		'new illuminator_str';
	lives_ok { $illuminator_uni = Frost::Illuminator->new ( classname => 'Foo', slotname => 'uni_str', data_root => $TMP_PATH ); }
		'new illuminator_uni';

	is $illuminator_num->slotname,	'foo_num',		'illuminator_num collects foo_num';
	is $illuminator_num->numeric,		true,				'illuminator_num sorts ascii';
	is $illuminator_num->unique,		false,			'illuminator_num holds duplicate keys';
	is $illuminator_num->filename,	$filename_num,	"illuminator_num collects in $filename_num";

	ok	! -e $filename_num, "$filename_num does not exist yet";

	lives_ok { $illuminator_num->collect ( 42, 142 ); }	'collect 42 -> 142 in illuminator_num';

	ok	-e $filename_num, "$filename_num does now exist";

	is $illuminator_str->slotname,	'foo_str',		'illuminator_str collects foo_str';
	is $illuminator_str->numeric,		false,			'illuminator_str sorts numeric';
	is $illuminator_str->unique,		false,			'illuminator_str holds duplicate keys';
	is $illuminator_str->filename,	$filename_str,	"illuminator_str collects in $filename_str";

	ok	! -e $filename_str, "$filename_str does not exist yet";

	lives_ok { $illuminator_str->collect ( 'Multi', 666 ); }		'collect Multi -> 666 in illuminator_str';

	ok	-e $filename_str, "$filename_str does now exist";

	is $illuminator_uni->slotname,	'uni_str',		'illuminator_uni collects foo_uni';
	is $illuminator_uni->numeric,		false,			'illuminator_uni sorts ascii';
	is $illuminator_uni->unique,		true,				'illuminator_uni holds unique keys';
	is $illuminator_uni->filename,	$filename_uni,	"illuminator_uni collects in $filename_uni";

	ok	! -e $filename_uni, "$filename_uni does not exist yet";

	lives_ok { $illuminator_uni->collect ( 'Uni', 1 ); }			'collect Uni -> 1 in illuminator_uni';

	ok	-e $filename_uni, "$filename_uni does now exist";

	#	will close, if references go away...
}

{
	my ( $illuminator_num, $illuminator_str, $illuminator_uni );
	my ( $id );

	lives_ok { $illuminator_num = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new illuminator_num';
	lives_ok { $illuminator_str = Frost::Illuminator->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new illuminator_str';
	lives_ok { $illuminator_uni = Frost::Illuminator->new ( classname => 'Foo', slotname => 'uni_str', data_root => $TMP_PATH ); }
		're-new illuminator_uni';

	ok	-e $filename_num, "$filename_num exists";
	ok	-e $filename_str, "$filename_str exists";
	ok	-e $filename_uni, "$filename_uni exists";

	lives_ok { $id = $illuminator_num->lookup ( 42 ); }			'lookup 42 in illuminator_num';
	is	$id,		142,			'got id 142 from illuminator_num';

	lives_ok { $id = $illuminator_str->lookup ( 'Multi' ); }	'lookup Multi in illuminator_str';
	is	$id,		666,			'got id 666 from illuminator_str';

	lives_ok { $id = $illuminator_uni->lookup ( 'Uni' ); }	'lookup Uni in illuminator_str';
	is	$id,		1,				'got id 1 from illuminator_str';
}

#	clear, remove and errors as in 030_cemetery.t...
