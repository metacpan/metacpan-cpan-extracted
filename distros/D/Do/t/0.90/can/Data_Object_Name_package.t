use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

package

=usage

  # given foo-bar__bar

  my $package = $name->package; # FooBar::Baz

=description

The package method returns a package name representation of the name given.

=signature

package() : Str

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "package";

is(Data::Object::Name->new('foo bar')->package, 'FooBar');
is(Data::Object::Name->new('foo-bar')->package, 'FooBar');
is(Data::Object::Name->new('foo-bar__baz')->package, 'FooBar::Baz');
is(Data::Object::Name->new('foo_bar')->package, 'FooBar');
is(Data::Object::Name->new('FooBar')->package, 'FooBar');
is(Data::Object::Name->new('Foo::Bar')->package, 'Foo::Bar');
is(Data::Object::Name->new('Foo\'Bar')->package, 'Foo::Bar');
is(Data::Object::Name->new('Foo:Bar')->package, 'FooBar');
is(Data::Object::Name->new('Foo_Bar')->package, 'Foo_Bar');
is(Data::Object::Name->new('Foo__Bar')->package, 'Foo__Bar');
is(Data::Object::Name->new('foo**bar')->package, 'FooBar');

ok 1 and done_testing;
