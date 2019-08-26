use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

parse

=usage

  # given Foo::Bar

  $space->parse('Foo::Bar');

  # ['Foo', 'Bar']

  $space->parse('Foo/Bar');

  # ['Foo', 'Bar']

  $space->parse('Foo\Bar');

  # ['Foo', 'Bar']

  $space->parse('foo-bar');

  # ['FooBar']

  $space->parse('foo_bar');

  # ['FooBar']

=description

The parse method parses the string argument and returns an arrayref of package
namespace segments (parts) suitable for object construction.

=signature

parse(Str $arg1) : ArrayRef

=type

method

=cut

# TESTING

use Data::Object::Space;

can_ok 'Data::Object::Space', 'parse';

ok 1 and done_testing;
