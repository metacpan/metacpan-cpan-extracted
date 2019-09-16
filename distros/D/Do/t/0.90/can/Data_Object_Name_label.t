use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

label

=usage

  # given Foo::Bar

  my $label = $name->label; # Foo_Bar

=description

The label method returns a label (or constant) representation of the name

=signature

label() : Str

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "label";

is(Data::Object::Name->new('foo bar')->label, 'FooBar');
is(Data::Object::Name->new('foo-bar')->label, 'FooBar');
is(Data::Object::Name->new('foo_bar')->label, 'FooBar');
is(Data::Object::Name->new('FooBar')->label, 'FooBar');
is(Data::Object::Name->new('Foo::Bar')->label, 'Foo_Bar');
is(Data::Object::Name->new('Foo\'Bar')->label, 'Foo_Bar');
is(Data::Object::Name->new('Foo:Bar')->label, 'FooBar');
is(Data::Object::Name->new('Foo_Bar')->label, 'Foo_Bar');
is(Data::Object::Name->new('Foo__Bar')->label, 'Foo__Bar');
is(Data::Object::Name->new('foo**bar')->label, 'FooBar');

ok 1 and done_testing;
