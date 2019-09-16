use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lookslike_a_package

=usage

  # given Foo::Bar

  $name->lookslike_a_package; # truthy

  # given Foo/Bar

  $name->lookslike_a_package; # falsy

=description

The lookslike_a_package method returns truthy if its state resembles a package
name.

=signature

lookslike_a_package() : Bool

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "lookslike_a_package";

ok(!Data::Object::Name->new('foo bar')->lookslike_a_package);
ok(!Data::Object::Name->new('foo-bar')->lookslike_a_package);
ok(!Data::Object::Name->new('foo_bar')->lookslike_a_package);
ok(Data::Object::Name->new('FooBar')->lookslike_a_package);
ok(Data::Object::Name->new('Foo::Bar')->lookslike_a_package);
ok(!Data::Object::Name->new('Foo\'Bar')->lookslike_a_package);
ok(!Data::Object::Name->new('Foo:Bar')->lookslike_a_package);
ok(Data::Object::Name->new('Foo_Bar')->lookslike_a_package);
ok(Data::Object::Name->new('Foo__Bar')->lookslike_a_package);
ok(!Data::Object::Name->new('foo**bar')->lookslike_a_package);

ok 1 and done_testing;
