use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

lookslike_a_path

=usage

  # given Foo::Bar

  $name->lookslike_a_path; # falsy

  # given Foo/Bar

  $name->lookslike_a_path; # truthy

=description

The lookslike_a_path method returns truthy if its state resembles a file path.

=signature

lookslike_a_path() : Bool

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "lookslike_a_path";

ok(!Data::Object::Name->new('foo bar')->lookslike_a_path);
ok(!Data::Object::Name->new('foo-bar')->lookslike_a_path);
ok(!Data::Object::Name->new('foo_bar')->lookslike_a_path);
ok(Data::Object::Name->new('FooBar')->lookslike_a_path);
ok(!Data::Object::Name->new('Foo::Bar')->lookslike_a_path);
ok(!Data::Object::Name->new('Foo\'Bar')->lookslike_a_path);
ok(Data::Object::Name->new('Foo:Bar')->lookslike_a_path);
ok(Data::Object::Name->new('Foo.Bar')->lookslike_a_path);
ok(!Data::Object::Name->new('Foo..Bar')->lookslike_a_path);
ok(Data::Object::Name->new('Foo\Bar')->lookslike_a_path);
ok(Data::Object::Name->new('Foo_Bar')->lookslike_a_path);
ok(Data::Object::Name->new('Foo__Bar')->lookslike_a_path);
ok(!Data::Object::Name->new('foo**bar')->lookslike_a_path);

ok 1 and done_testing;
