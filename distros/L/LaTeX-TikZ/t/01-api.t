#!perl -T

use strict;
use warnings;

use Test::More tests => 5 + 24 + 12;

use LaTeX::TikZ;

ok(defined &Tikz,         'main::Tikz constant is defined');
is(prototype('Tikz'), '', 'main::Tikz is actually a constant');

{
 package LaTeX::TikZ::TestAPI1;

 eval {
  LaTeX::TikZ->import(as => ':)');
 };
 ::like($@, qr/^Invalid name/, 'invalid name');
}

{
 package LaTeX::TikZ::TestAPI2;

 use LaTeX::TikZ as => 'T';

 ::ok(defined &T,         'LaTeX::TikZ::TestAPI2::T constant is defined');
 ::is(prototype('T'), '', 'LaTeX::TikZ::TestAPI2::T is actually a constant');
}

my @methods = qw<
 formatter functor
 raw
 union path seq chain join
 point line polyline closed_polyline rectangle circle arc arrow
 raw_mod
 clip layer
 scale width color fill pattern
>;

for (@methods) {
 ok(Tikz->can($_), "Tikz evaluates to something that ->can($_)");
}

require LaTeX::TikZ::Interface;

for my $name (undef, ':)') {
 eval {
  LaTeX::TikZ::Interface->register(
   $name => sub { },
  );
 };
 like $@, qr/^Invalid interface name/, 'invalid interface name';
}

eval {
 LaTeX::TikZ::Interface->register(
  'raw' => sub { },
 );
};
like $@, qr/^'raw' is already defined/, 'already defined';

for my $code (undef, [ ]) {
 eval {
  LaTeX::TikZ::Interface->register(
   'foo' => $code,
  );
 };
 like $@, qr/^Invalid code reference/, 'invalid code';
}

eval {
 LaTeX::TikZ::Interface->register(
  'foo' => sub { @_ },
 );
};
is $@,           '', 'registering foo doesn\'t croak';
ok(Tikz->can('foo'), 'Tikz evaluates to something that ->can(foo)');
is_deeply [ Tikz->foo('hello') ], [ Tikz, 'hello' ], 'Tikz->foo works';

eval {
 LaTeX::TikZ::Interface->register(
  'bar' => sub { @_ },
  'baz' => undef,
 );
};
like $@, qr/^Invalid code reference/, 'baz is invalid code';
ok(!Tikz->can('baz'), 'baz was not defined');
ok(Tikz->can('bar'),  'but bar was defined');
is_deeply [ Tikz->bar('bonjour') ], [ Tikz, 'bonjour' ], 'Tikz->bar works';
