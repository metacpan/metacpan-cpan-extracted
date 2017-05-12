#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 2;

{
	package Foo;

	use Keyword::Simple;

	sub import {
		Keyword::Simple::define peek => sub {
			substr ${$_[0]}, 0, 0, "ok 1, 'synthetic test';";
		};
	}

	sub unimport {
		Keyword::Simple::undefine 'peek';
	}

	BEGIN { $INC{"Foo.pm"} = 1; }
}

use Foo;

peek
ok 1, "natural test";
