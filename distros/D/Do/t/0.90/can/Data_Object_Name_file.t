use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

file

=usage

  # given FooBar::Baz

  my $file = $name->file; # foo_bar__baz

=description

The file method returns a file representation of the name.

=signature

file() : Str

=type

method

=cut

# TESTING

use Data::Object::Name;

can_ok "Data::Object::Name", "file";

is(Data::Object::Name->new('foo bar')->file, 'foo_bar');
is(Data::Object::Name->new('foo-bar')->file, 'foo_bar');
is(Data::Object::Name->new('foo_bar')->file, 'foo_bar');
is(Data::Object::Name->new('FooBar')->file, 'foo_bar');
is(Data::Object::Name->new('Foo::Bar')->file, 'foo__bar');
is(Data::Object::Name->new('Foo\'Bar')->file, 'foo__bar');
is(Data::Object::Name->new('Foo:Bar')->file, 'foo_bar');
is(Data::Object::Name->new('Foo_Bar')->file, 'foo_bar');
is(Data::Object::Name->new('Foo__Bar')->file, 'foo__bar');
is(Data::Object::Name->new('foo**bar')->file, 'foo_bar');

ok 1 and done_testing;
