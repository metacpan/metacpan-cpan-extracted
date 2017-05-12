use Evo;
use Test::More;
use Evo::Internal::Exception;

sub parse { [Evo::_parse('My::Caller', @_)] }
sub parse_from { [Evo::_parse(@_)] }


is_deeply parse('Foo'),      ['Foo',      0];
is_deeply parse('Foo::Bar'), ['Foo::Bar', 0];

is_deeply parse('Foo(bar baz)'),       [qw(Foo 0 bar baz)];
is_deeply parse('Foo::Bar (bar baz)'), [qw(Foo::Bar 0 bar baz)];
is_deeply parse('Foo(bar,baz)'),       [qw(Foo 0  bar baz)];
is_deeply parse('Foo (bar,baz)'),      [qw(Foo 0  bar baz)];
is_deeply parse('Foo (bar baz)'),      [qw(Foo 0  bar baz)];
is_deeply parse('Foo [bar baz]'),      [qw(Foo 0 bar baz)];

is_deeply parse('Foo(:all)'), [qw(Foo 0  :all)];

is_deeply parse('Foo bar baz'), [qw(Foo 0 bar baz)];
is_deeply parse('Foo bar,baz'), [qw(Foo 0  bar baz)];

is_deeply parse('-Foo'),         [qw(Evo::Foo 0)];
is_deeply parse('-Foo bar baz'), [qw(Evo::Foo 0  bar baz)];
is_deeply parse('-33 bar baz'),  [qw(Evo::33 0 bar baz)];

is_deeply parse('-Foo [bar baz]'),  [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo (bar, baz)'), [qw(Evo::Foo 0 bar baz)];

is_deeply parse('-Foo[bar baz]'),  [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo[bar, baz]'), [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo[bar, baz]'), [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo[bar,baz]'),  [qw(Evo::Foo 0 bar baz)];

is_deeply parse('-Foo(bar baz)'),  [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo(bar, baz)'), [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo(bar, baz)'), [qw(Evo::Foo 0 bar baz)];
is_deeply parse('-Foo(bar,baz)'),  [qw(Evo::Foo 0 bar baz)];

# empty args
is_deeply parse('-Foo ()'),  [qw(Evo::Foo 1)];
is_deeply parse('-Foo( ) '), [qw(Evo::Foo 1)];

# new lines
is_deeply parse("Foo \nbar\n\nbaz"), [qw(Foo 0  bar baz)];

# trim
is_deeply parse(' My::Foo '),         [qw(My::Foo 0)];
is_deeply parse(' My::Foo bar baz '), [qw(My::Foo 0 bar baz)];

# /:: => parent
is_deeply parse_from('My::Foo', '/::Bar::Baz'),        [qw(My::Bar::Baz 0)];
is_deeply parse_from('My::Foo', '/::Bar hello there'), [qw(My::Bar 0 hello there)];
is_deeply parse_from('My::Foo', '/ hello there'),      [qw(My 0 hello there)];
is_deeply parse_from('My::Foo', '/::33 hello there'),  [qw(My::33 0 hello there)];

# : => current
is_deeply parse_from('My::Foo', '::Bar::Baz'),        [qw(My::Foo::Bar::Baz 0)];
is_deeply parse_from('My::Foo', '::Bar hello there'), [qw(My::Foo::Bar 0 hello there)];
is_deeply parse_from('My::Foo', '::33 hello there'),  [qw(My::Foo::33 0 hello there)];

done_testing;
