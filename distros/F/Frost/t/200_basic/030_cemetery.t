#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 140;
#use Test::More 'no_plan';

use_ok 'Frost::Cemetery';

{
	package Foo;			#	must exist for type ClassName

	use Moose;

	has id		=> ( is => 'rw', isa => 'Int' );		#	must exist for attribute check
	has foo_num	=> ( is => 'rw', isa => 'Int' );		#	must exist for attribute check
	has foo_str	=> ( is => 'rw', isa => 'Str' );		#	must exist for attribute check

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

is		Frost::Cemetery->suffix(),	'.cem',	'suffix is .cem';

my $regex;

{
	$regex	= qr/Attribute \((data_root|classname|slotname)\) is required/;

	throws_ok	{ my $cemetery = Frost::Cemetery->new; }
		$regex,	'Cemetery->new';

	throws_ok	{ my $cemetery = Frost::Cemetery->new(); }
		$regex,	'Cemetery->new()';

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( classname => 'Foo' ); }
		$regex,	'Param data_root and slotname missing';

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( slotname => 'foo_num' ); }
		$regex,	'Param data_root and classname missing';

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( slotname => 'foo_str' ); }
		$regex,	'Param data_root and classname missing';

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num' ); }
		$regex,	'Param data_root missing';

	$regex	= qr/Class 'Bar' has no attribute 'foo_num'/;

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( classname => 'Bar', slotname => 'foo_num', data_root => $TMP_PATH ); }
		$regex,	'Bad slotname in Bar';

	$regex	= qr/Class 'Foo' has no attribute 'bar'/;

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( classname => 'Foo', slotname => 'bar', data_root => $TMP_PATH ); }
		$regex,	'Bad slotname in Foo';

#	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' failed .* $TMP_PATH_NIX/;
#	Moose 1.05:
	$regex	= qr/Attribute \(data_root\) does not pass the type constraint .* 'Frost::FilePathMustExist' .* $TMP_PATH_NIX/;

	throws_ok	{ my $cemetery = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH_NIX ); }
		$regex,	'Bad data_root';
}

my $filename_num	= make_file_path $TMP_PATH, 'Foo', 'foo_num.cem';
my $filename_str	= make_file_path $TMP_PATH, 'Foo', 'foo_str.cem';

{
	my ( $cemetery_num, $cemetery_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		'new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		'new cemetery_str';

	is $cemetery_num->slotname,	'foo_num',		'cemetery_num entombs foo_num';
	is $cemetery_num->numeric,		true,				'cemetery_num sorts numeric ids';
	is $cemetery_num->unique,		true,				'cemetery_num holds unique keys';
	is $cemetery_num->filename,	$filename_num,	"cemetery_num entombs in $filename_num";

	is	$cemetery_num->is_open,		false,			'cemetery_num is not open';
	is	$cemetery_num->is_closed,	true,				'cemetery_num is closed';

	ok	!	-e $filename_num, "$filename_num does not exist yet";

	lives_ok { $cemetery_num->entomb ( 1, 42 ); }		'entomb 1 -> 42 in cemetery_num';

	is	$cemetery_num->is_open,		true,				'cemetery_num is open';
	is	$cemetery_num->is_closed,	false,			'cemetery_num is not closed';

	ok		-e $filename_num, "$filename_num exists now";

	is $cemetery_str->slotname,	'foo_str',		'cemetery_str entombs foo_str';
	is $cemetery_str->numeric,		true,				'cemetery_str sorts numeric ids';
	is $cemetery_str->unique,		true,				'cemetery_str holds unique keys';
	is $cemetery_str->filename,	$filename_str,	"cemetery_str entombs in $filename_str";

	is	$cemetery_str->is_open,		false,			'cemetery_str is not open';
	is	$cemetery_str->is_closed,	true,				'cemetery_str is closed';

	ok	!	-e $filename_str, "$filename_str does not exist yet";

	lives_ok { $cemetery_str->entomb ( 1, 'Essence' ); }		'entomb 1 -> "Essence" in cemetery_str';

	is	$cemetery_str->is_open,		true,				'cemetery_str is open';
	is	$cemetery_str->is_closed,	false,			'cemetery_str is not closed';

	ok		-e $filename_str, "$filename_str exists now";

	#	will save and close, if references go away...
}

{
	my ( $cemetery_num, $cemetery_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new cemetery_str';

	ok		-e $filename_num, "$filename_num exists";
	ok		-e $filename_str, "$filename_str exists";

	is	$cemetery_num->is_closed,	true,				'cemetery_num is closed';
	is	$cemetery_str->is_closed,	true,				'cemetery_str is closed';

	lives_ok { $cemetery_num->open }		'open cemetery_num';

	is	$cemetery_num->is_open,		true,				'cemetery_num is open';
	is	$cemetery_str->is_closed,	true,				'cemetery_str is closed';

	lives_ok { $cemetery_str->open }		'open cemetery_str';

	is	$cemetery_num->is_open,		true,				'cemetery_num is open';
	is	$cemetery_str->is_open,		true,				'cemetery_str is open';

	lives_ok { $cemetery_num->open }		're-open cemetery_num ok';
	lives_ok { $cemetery_str->open }		're-open cemetery_str ok';

	lives_ok { $cemetery_num->close }	'close cemetery_num';

	is	$cemetery_num->is_closed,	true,				'cemetery_num is closed';
	is	$cemetery_str->is_open,		true,				'cemetery_str is open';

	lives_ok { $cemetery_str->close }	'close cemetery_str';

	is	$cemetery_num->is_closed,	true,				'cemetery_num is closed';
	is	$cemetery_str->is_closed,	true,				'cemetery_str is closed';

	lives_ok { $cemetery_num->close }	're-close cemetery_num';
	lives_ok { $cemetery_str->close }	're-close cemetery_str';
}

{
	my ( $cemetery_num, $cemetery_str, $essence_num, $essence_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new cemetery_str';

	lives_ok { $essence_num = $cemetery_num->exhume ( 1 ); }		'exhume 1 -> 42 from cemetery_num';

	is	$essence_num,		42,			'got the right essence from cemetery_num';

	lives_ok { $essence_str = $cemetery_str->exhume ( 1 ); }		'exhume 1 -> "Essence" from cemetery_str';

	is	$essence_str,		"Essence",		'got the right essence from cemetery_str';

	is	$cemetery_num->count ( ),	1,	'cemetery_num counts 1 essence';
	is	$cemetery_str->count ( ),	1,	'cemetery_str counts 1 essence';

	lives_ok { $cemetery_num->entomb ( 2, 666 ); }			'entomb 2 -> 666 in cemetery_num';
	lives_ok { $cemetery_str->entomb ( 2, 'Zombie' ); }	'entomb 2 -> Zombie in cemetery_str';
	lives_ok { $cemetery_str->entomb ( 3, 'Dracula' ); }	'entomb 3 -> Dracula in cemetery_str';

	is	$cemetery_num->count ( ),	2,	'cemetery_num counts 2 essences';
	is	$cemetery_str->count ( ),	3,	'cemetery_str counts 3 essences';

	lives_ok { $cemetery_num->forget ( 1 ); }			'forget 1 in cemetery_num';
	lives_ok { $cemetery_str->forget ( 1 ); }			'forget 1 in cemetery_str';

	is	$cemetery_num->count ( ),	1,	'cemetery_num counts 1 essence';
	is	$cemetery_str->count ( ),	2,	'cemetery_str counts 2 essences';

	lives_ok { $essence_num = $cemetery_num->exhume ( 1 ); }		'exhume 1 from cemetery_num';
	isnt	$essence_num,		42,			'got no essence from cemetery_num';

	lives_ok { $essence_num = $cemetery_num->exhume ( 2 ); }		'exhume 1 from cemetery_num';
	is		$essence_num,		666,			'got 666 from cemetery_num';

	lives_ok { $essence_str = $cemetery_str->exhume ( 1 ); }		'exhume 1 from cemetery_str';
	isnt	$essence_str,		'Essence',	'got no essence from cemetery_str';

	lives_ok { $essence_str = $cemetery_str->exhume ( 2 ); }		'exhume 2 from cemetery_str';
	is		$essence_str,		'Zombie',	'got Zombie from cemetery_str';

	lives_ok { $essence_str = $cemetery_str->exhume ( 3 ); }		'exhume 3 from cemetery_str';
	is		$essence_str,		'Dracula',	'got Dracula from cemetery_str';

	lives_ok { $cemetery_num->clear }		'clear cemetery_num';
	lives_ok { $cemetery_str->clear }		'clear cemetery_str';

	#	will save and close, if references go away...
}

{
	my ( $cemetery_num, $cemetery_str, $essence_num, $essence_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new cemetery_str';

	is	$cemetery_num->count ( ),	0,	'cemetery_num counts no essences';
	is	$cemetery_str->count ( ),	0,	'cemetery_str counts no essences';

	lives_ok { $essence_num = $cemetery_num->exhume ( 1 ); }		'exhume 1 -> 42 from cemetery_num';
	isnt	$essence_num,		42,				'got no essence from cemetery_num';

	lives_ok { $essence_str = $cemetery_str->exhume ( 1 ); }		'exhume 1 -> "Essence" from cemetery_str';
	isnt	$essence_str,		"Essence",		'got no essence from cemetery_str';

	is	$cemetery_num->is_open,		true,				'cemetery_num is open';
	is	$cemetery_str->is_open,		true,				'cemetery_str is open';

	lives_ok { $cemetery_num->remove }		'remove cemetery_num';
	lives_ok { $cemetery_str->remove }		'remove cemetery_str';

	is	$cemetery_num->is_closed,	true,				'cemetery_num is closed';
	is	$cemetery_str->is_closed,	true,				'cemetery_str is closed';

	ok	!	-e $filename_num, "$filename_num is gone";
	ok	!	-e $filename_str, "$filename_str is gone";

	lives_ok { $cemetery_str->entomb ( 3,	'Dracula' ); }			'entomb 3 -> Dracula in cemetery_str again';
	lives_ok { $cemetery_str->entomb ( 4,	'Frankenstein' ); }	'entomb 4 -> Frankenstein in cemetery_str';

	#	will save and close, if references go away...
}

{
	my ( $cemetery_num, $cemetery_str, $essence_num, $essence_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new cemetery_str';

	ok	!	-e $filename_num, "$filename_num was gone";
	ok		-e $filename_str, "$filename_str exists";

	lives_ok { $essence_str = $cemetery_str->exhume ( 3 ); }		'exhume 3 from cemetery_str';
	is		$essence_str,		"Dracula",				'got Dracula from cemetery_str';

	lives_ok { $essence_str = $cemetery_str->exhume ( 4 ); }		'exhume 4 from cemetery_str';
	is		$essence_str,		"Frankenstein",		'got Frankenstein from cemetery_str';

	ok	!	-e $filename_num, "$filename_num still gone";

	is	$cemetery_num->count ( ),	0,	'cemetery_num counts no essences';
	is	$cemetery_str->count ( ),	2,	'cemetery_str counts 2 essences';

	ok		-e $filename_num, "$filename_num exists after count";
}

{
	my ( $cemetery_num, $cemetery_str, $essence_num, $essence_str );

	lives_ok { $cemetery_num = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
		're-new cemetery_num';
	lives_ok { $cemetery_str = Frost::Cemetery->new ( classname => 'Foo', slotname => 'foo_str', data_root => $TMP_PATH ); }
		're-new cemetery_str';

	my $count;

	lives_ok	{ $count = $cemetery_num->count(); }			'cemetery_num->count()';			is		$count,	0,		'= 0';
	lives_ok	{ $count = $cemetery_num->count ( 3 ); }		'cemetery_num->count ( 3 )';		is		$count,	0,		'= 0';
	dies_ok	{ $count = $cemetery_num->count ( \3 ); }		'cemetery_num->count ( \3 ) dies';
	lives_ok	{ $count = $cemetery_num->count ( "x" ); }	'cemetery_num->count ( "x" )';	is		$count,	0,		'= 0';
	lives_ok	{ $count = $cemetery_num->count ( "" ); }		'cemetery_num->count ( "" )';		is		$count,	0,		'= 0';
	lives_ok	{ $count = $cemetery_num->count ( 4 ); }		'cemetery_num->count ( 4 )';		is		$count,	0,		'= 0';

	lives_ok	{ $count = $cemetery_str->count(); }			'cemetery_str->count()';			is		$count,	2,		'= 2';
	lives_ok	{ $count = $cemetery_str->count ( 3 ); }		'cemetery_str->count ( 3 )';		is		$count,	1,		'= 1';
	dies_ok	{ $count = $cemetery_str->count ( \3 ); }		'cemetery_str->count ( \3 ) dies';
	lives_ok	{ $count = $cemetery_str->count ( "x" ); }	'cemetery_str->count ( "x" )';	is		$count,	0,		'= 0';
	lives_ok	{ $count = $cemetery_str->count ( "" ); }		'cemetery_str->count ( "" )';		is		$count,	0,		'= 0';
	lives_ok	{ $count = $cemetery_str->count ( 4 ); }		'cemetery_str->count ( 4 )';		is		$count,	1,		'= 1';
}
