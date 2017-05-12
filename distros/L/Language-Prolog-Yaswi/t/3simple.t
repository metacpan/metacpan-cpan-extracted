#!/usr/bin/perl

use Test::More tests => 27;

use strict;
use warnings;

use Language::Prolog::Types ':short';
use Language::Prolog::Types::overload;
use Language::Prolog::Sugar functors => [qw( man god mortal tubolize foobolize bartolize)],
                            vars     => [qw( X )];

use Language::Prolog::Yaswi qw(:query :assert :load :context);

swi_assert(mortal(X) => man(X));

swi_facts(man('socrates'),
	  man('bush'),
	  god('zeus'));


swi_set_query(mortal(X));

ok( swi_next(), 'swi_next 1');
is( swi_var(X), 'socrates', 'swi_var 1');

ok( swi_next(), 'swi_next 2');
is( swi_var(X), 'bush', 'swi_var 2');

ok( !swi_next(), 'swi_next ends');

is_deeply( [swi_find_all(man(X),X)], ['socrates', 'bush'], 'swi_find_all');

is( swi_find_one(god(X), X), 'zeus', 'swi_find_one');

swi_inline <<CODE;

tubolize(foo).
tubolize(bar).

tubolize(X, X).

CODE

is_deeply( [swi_find_all(tubolize(X), X )], [qw(foo bar)], "swi_inline");

for (1..10) {
    # my $uni = pack "U*" => map rand(2**30), 1..10+rand(20);
    my $uni = pack "b*" => map rand(2**6), 1..10+rand(20);
    is (swi_find_one(tubolize($uni, X), X), $uni, "unicode $_");
}

swi_inline_module <<CODE;

:- module(foo, [foobolize/1]).

foobolize(foo).
foobolize(bar).

bartolize(9).

CODE

is_deeply( [swi_find_all(foobolize(X), X )], [qw(foo bar)], "swi_inline_module");

{
  local $swi_module = 'foo';
  is ( swi_find_one( bartolize(X), X), 9, '$swi_module');
}

binmode STDERR, ":utf8";
binmode STDOUT, ":utf8";

my @unicode = ( "\x{279}\x{251}jd\x{26a}\x{14b} \x{251}j pij ej k\x{25b}\x{279}\x{259}kt\x{25a}z \x{268}z izi",
                "Il est tr\xe8s facile d\x{2019}\xe9crire des caract\xe8res fran\xe7ais.",
                "\x{5beb}\x{6f22}\x{5b57}\x{5f88}\x{5bb9}\x{6613}\x{3002}",
                "\x{41f}\x{438}\x{441}\x{430}\x{442}\x{44c} \x{43f}\x{43e}-\x{440}\x{443}\x{441}\x{441}\x{43a}\x{438} \x{43b}\x{435}\x{433}\x{43a}\x{43e}.",
                "Es muy f\xe1cil escribir en espa\xf1ol.",
                "\x{6f22}\x{5b57}\x{3067}\x{66f8}\x{304d}\x{3084}\x{3059}\x{3044}\x{3067}\x{3059}\x{3002}" );

for (@unicode) {
    is_deeply( [swi_find_all(tubolize($_, X), X )], [$_], "unicode");
}

my $unicode_functor = F("\x{5beb}\x{6f22}\x{5b57}\x{5f88}\x{5bb9}\x{6613}\x{3002}", @unicode);
is_deeply( [swi_find_all(tubolize($unicode_functor, X), X )], [$unicode_functor], "unicode functor");
