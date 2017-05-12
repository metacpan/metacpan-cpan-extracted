#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 14;
#use Test::More 'no_plan';

use_ok 'Frost::Burial';

throws_ok	{ Frost::Burial->suffix()			}	qr/Abstract method/,	'suffix         is an abstract method';
throws_ok	{ Frost::Burial->_build_numeric()	}	qr/Abstract method/,	'_build_numeric is an abstract method';
throws_ok	{ Frost::Burial->_build_unique()	}	qr/Abstract method/,	'_build_unique  is an abstract method';

my $regex	= qr/Frost::Burial is an abstract class/;

throws_ok	{ my $burial = Frost::Burial->new; }
	$regex,	'Burial->new (abstract)';

throws_ok	{ my $burial = Frost::Burial->new(); }
	$regex,	'Burial->new() (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Foo' ); }
	$regex,	'Param data_root and slotname missing (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( slotname => 'foo_num' ); }
	$regex,	'Param data_root and classname missing (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( slotname => 'foo_str' ); }
	$regex,	'Param data_root and classname missing (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Foo', slotname => 'foo_num' ); }
	$regex,	'Param data_root missing (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Bar', slotname => 'foo_num', data_root => $TMP_PATH ); }
	$regex,	'Bad slotname in Bar (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Foo', slotname => 'bar', data_root => $TMP_PATH ); }
	$regex,	'Bad slotname in Foo (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH_NIX ); }
	$regex,	'Bad data_root (abstract)';

throws_ok	{ my $burial = Frost::Burial->new ( classname => 'Foo', slotname => 'foo_num', data_root => $TMP_PATH ); }
	$regex,	'Params ok (abstract)';
