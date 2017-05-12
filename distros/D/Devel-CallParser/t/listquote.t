use warnings;
use strict;

use Test::More tests => 47;
use t::LoadXS ();
use t::WriteHeader ();

t::WriteHeader::write_header("callparser0", "t", "listquote");
ok 1;
require_ok "Devel::CallParser";
t::LoadXS::load_xs("listquote", "t",
	[Devel::CallParser::callparser_linkable()]);
ok 1;

my($foo_got, $foo_ret);
sub foo { $foo_got = [ @_ ]; return "z"; }

$foo_got = undef;
eval q{$foo_ret = foo 1231;};
is $@, "";
is_deeply $foo_got, [ 1231 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = &foo(1231);};
is $@, "";
is_deeply $foo_got, [ 1231 ];
is $foo_ret, "z";

t::listquote::cv_set_call_parser_listquote(\&foo, "xyz");

$foo_got = undef;
eval q{$foo_ret = foo 1231;};
is $@, "";
is_deeply $foo_got, [ "xyz", "2", "3" ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = &foo(1231);};
is $@, "";
is_deeply $foo_got, [ 1231 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = foo:ab cd:;};
is $@, "";
is_deeply $foo_got, [ "xyz", "a", "b", " ", "c", "d" ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = foo!ab cd!;};
isnt $@, "";
is $foo_got, undef;

$foo_got = undef;
eval q{foo!ab cd!;};
is $@, "";
is_deeply $foo_got, [ "xyz", "a", "b", " ", "c", "d" ];

$foo_got = undef; $foo_ret = undef;
eval q{foo!ab cd! package main; $foo_ret = "z";};
is $@, "";
is_deeply $foo_got, [ "xyz", "a", "b", " ", "c", "d" ];
is $foo_ret, "z";

$foo_got = undef; $foo_ret = undef;
eval q{foo:ab cd: package main; $foo_ret = "z";};
isnt $@, "";
is $foo_got, undef;

*bar = \&foo; *bar = \&foo;

$foo_got = undef;
eval q{$foo_ret = bar:ab cd:;};
is $@, "";
is_deeply $foo_got, [ "xyz", "a", "b", " ", "c", "d" ];
is $foo_ret, "z";

*wibble::baz = \&foo; *wibble::baz = \&foo;

$foo_got = undef;
eval q{package wibble; $foo_ret = baz:ab cd:;};
is $@, "";
is_deeply $foo_got, [ "xyz", "a", "b", " ", "c", "d" ];
is $foo_ret, "z";

sub bin($$) { $foo_got = [ @_ ]; return "z"; }

$foo_got = undef;
eval q{$foo_ret = bin 1, 2;};
is $@, "";
is_deeply $foo_got, [ 1, 2 ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = bin 1;};
isnt $@, "";
is $foo_got, undef;

$foo_got = undef;
eval q{$foo_ret = bin 1, 2, 3;};
isnt $@, "";
is $foo_got, undef;

t::listquote::cv_set_call_parser_listquote(\&bin, "aaa");

$foo_got = undef;
eval q{$foo_ret = bin|b|;};
is $@, "";
is_deeply $foo_got, [ "aaa", "b" ];
is $foo_ret, "z";

$foo_got = undef;
eval q{$foo_ret = bin||;};
isnt $@, "";
is $foo_got, undef;

$foo_got = undef;
eval q{$foo_ret = bin|bc|;};
isnt $@, "";
is $foo_got, undef;

1;
