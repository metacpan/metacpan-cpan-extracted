use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

format

=usage

  # given Foo::Bar

  $name->format('file', '%s.t'); # foo__bar.t

  # given Foo::Bar

  $name->format('path', '%s.pm'); # Foo/Bar.pm

=description

The format method called the specified method and passes the result to the core
L<perlfunc/sprintf> function with the string representation of itself as the
argument

=signature

format(Str $method, Str $format) : Str

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "format";

is(Data::Object::Name->new('FooBar')->format('file', '%s.t'), 'foo_bar.t');
is(Data::Object::Name->new('FooBar')->format('path', '%s.pm'), 'FooBar.pm');
is(Data::Object::Name->new('Foo::Bar')->format('file', '%s.t'), 'foo__bar.t');
is(Data::Object::Name->new('Foo::Bar')->format('path', '%s.pm'), 'Foo/Bar.pm');
is(Data::Object::Name->new('FooBar::Baz')->format('file', '%s.t'), 'foo_bar__baz.t');
is(Data::Object::Name->new('FooBar::Baz')->format('path', '%s.pm'), 'FooBar/Baz.pm');

ok 1 and done_testing;
