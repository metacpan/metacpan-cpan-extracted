#!perl
use warnings FATAL => 'all';
use strict;

use Test::More tests => 4;

{
    package Foo;

    use Keyword::Pluggable;

    sub import {
        Keyword::Pluggable::define 
		keyword    => 'peek',
		code       => "ok 1, 'synthetic test 1';",
		expression => 0,
	;

        Keyword::Pluggable::define 
		keyword    => 'poke', 
		code       => sub { substr ${$_[0]}, 0, 0, "ok 2, 'synthetic test 2';" },
		expression => 1,
	;
    }

    sub unimport {
        Keyword::Pluggable::undefine keyword => 'peek';
        Keyword::Pluggable::undefine keyword => 'poke';
    }

    BEGIN { $INC{"Foo.pm"} = 1; }
}

use Foo;

peek
ok 1, "natural test 1";
poke
ok 2, "natural test 2";
