use warnings;
use strict;

use Test::More tests => 10;

{
	use Lexical::Import (
		[qw(t::Exp0 successor)],
		[qw(t::Exp1 foo)],
	);
	ok defined(&successor);
	ok !defined(&predecessor);
	ok defined(&foo);
	ok !defined(&bar);
	is successor(5), 6;
	is foo(), "FOO";
}

ok !defined(&successor);
ok !defined(&predecessor);
ok !defined(&foo);
ok !defined(&bar);

1;
