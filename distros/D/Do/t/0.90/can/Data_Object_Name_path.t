use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

path

=usage

  # given Foo::Bar

  my $path = $name->path; # Foo/Bar

=description

The path method returns a path representation of the name.

=signature

path() : Str

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "path";

is(Data::Object::Name->new('foo bar')->path, 'FooBar');
is(Data::Object::Name->new('foo-bar')->path, 'FooBar');
is(Data::Object::Name->new('foo_bar')->path, 'FooBar');
is(Data::Object::Name->new('FooBar')->path, 'FooBar');
is(Data::Object::Name->new('Foo::Bar')->path, 'Foo/Bar');
is(Data::Object::Name->new('Foo\'Bar')->path, 'Foo/Bar');
is(Data::Object::Name->new('Foo:Bar')->path, 'Foo:Bar');
is(Data::Object::Name->new('Foo\Bar')->path, 'Foo\Bar');
is(Data::Object::Name->new('Foo.Bar')->path, 'Foo.Bar');
is(Data::Object::Name->new('Foo_Bar')->path, 'Foo_Bar');
is(Data::Object::Name->new('Foo__Bar')->path, 'Foo__Bar');
is(Data::Object::Name->new('foo**bar')->path, 'FooBar');
is(Data::Object::Name->new('foo__bar')->path, 'Foo/Bar');

ok 1 and done_testing;
