use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  # given $string

  my $name = Data::Object::Name->new($string);

=description

The new method returns instantiates the class and returns an object.

=signature

new(Str $arg) : Object

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "new";

isa_ok(Data::Object::Name->new, 'Data::Object::Name');
isa_ok(Data::Object::Name->new('foo bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('foo bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('foo'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('foo_bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('FooBar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('Foo::Bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('Foo\'Bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('Foo:Bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('Foo_Bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('Foo__Bar'), 'Data::Object::Name');
isa_ok(Data::Object::Name->new('foo**bar'), 'Data::Object::Name');

ok 1 and done_testing;
