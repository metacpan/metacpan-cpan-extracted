#!perl
use warnings FATAL => 'all';
use strict;

BEGIN {
    package Foo;

    use Keyword::Pluggable;

        Keyword::Pluggable::define 
		keyword    => 'peek',
		code       => "ok 1, 'synthetic test 1';",
		expression => 0,
		global     => 1,
	;

        Keyword::Pluggable::define 
		keyword    => 'poke', 
		code       => "ok 2, 'synthetic test 2';",
		expression => 1,
		global     => 1,
	;
}

{
	package Bar;
	use Test::More tests => 4;
	peek
	ok 1, "natural test 1";
	poke
	ok 2, "natural test 2";
}
