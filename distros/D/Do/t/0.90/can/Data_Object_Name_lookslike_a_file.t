use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lookslike_a_file

=usage

  # given foo_bar

  $name->lookslike_a_file; # truthy

  # given Foo/Bar

  $name->lookslike_a_file; # falsy

=description

The lookslike_a_file method returns truthy if its state resembles a filename.

=signature

lookslike_a_file() : Bool

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "lookslike_a_file";

ok(!Data::Object::Name->new('foo bar')->lookslike_a_file);
ok(!Data::Object::Name->new('foo-bar')->lookslike_a_file);
ok(Data::Object::Name->new('foo_bar')->lookslike_a_file);
ok(!Data::Object::Name->new('FooBar')->lookslike_a_file);
ok(!Data::Object::Name->new('Foo::Bar')->lookslike_a_file);
ok(!Data::Object::Name->new('Foo\'Bar')->lookslike_a_file);
ok(!Data::Object::Name->new('Foo:Bar')->lookslike_a_file);
ok(!Data::Object::Name->new('Foo_Bar')->lookslike_a_file);
ok(!Data::Object::Name->new('Foo__Bar')->lookslike_a_file);
ok(!Data::Object::Name->new('foo**bar')->lookslike_a_file);

ok 1 and done_testing;
