use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lookslike_a_label

=usage

  # given Foo_Bar

  $name->lookslike_a_label; # truthy

  # given Foo/Bar

  $name->lookslike_a_label; # falsy

=description

The lookslike_a_label method returns truthy if its state resembles a label (or constant).

=signature

lookslike_a_label() : Bool

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "lookslike_a_label";

ok(!Data::Object::Name->new('foo bar')->lookslike_a_label);
ok(!Data::Object::Name->new('foo-bar')->lookslike_a_label);
ok(!Data::Object::Name->new('foo_bar')->lookslike_a_label);
ok(Data::Object::Name->new('FooBar')->lookslike_a_label);
ok(!Data::Object::Name->new('Foo::Bar')->lookslike_a_label);
ok(!Data::Object::Name->new('Foo\'Bar')->lookslike_a_label);
ok(!Data::Object::Name->new('Foo:Bar')->lookslike_a_label);
ok(Data::Object::Name->new('Foo_Bar')->lookslike_a_label);
ok(Data::Object::Name->new('Foo__Bar')->lookslike_a_label);
ok(!Data::Object::Name->new('foo**bar')->lookslike_a_label);

ok 1 and done_testing;
