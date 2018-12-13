#!perl
use warnings FATAL => 'all';
use strict;

package Bar;
BEGIN {
    package Foo;

    use Keyword::Pluggable;

        Keyword::Pluggable::define 
		keyword    => 'peek',
		code       => sub { substr ${$_[0]}, 0, 0, "ok 1, 'synthetic test 1';" },
		expression => 0,
		package    => 'Bar',
	;

        Keyword::Pluggable::define 
		keyword    => 'poke', 
		code       => "ok 2, 'synthetic test 2';",
		expression => 1,
		package    => 'Bar',
	;
}

package Bar;
use Test::More tests => 6;

peek
ok 1, "natural test 1";
poke
ok 2, "natural test 2";

Keyword::Pluggable::undefine keyword => 'poke', package => 'Bar';
eval "poke;";
Test::More::ok(defined($@), 'failed outside package ok');

package Meke;
eval "peek;";
Test::More::ok(defined($@), 'failed outside package ok');
