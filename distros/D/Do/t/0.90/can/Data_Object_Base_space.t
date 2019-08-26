use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

space

=usage

  # given $self (Foo::Bar)

  $self->space();

  # Foo::Bar (space object)

  $self->space('Foo/Baz');

  # Foo::Baz (space object)

=description

The space method returns a L<Data::Object::Space> object for the given class,
object or argument.

=signature

space(Str $arg1) : Object

=type

method

=cut

# TESTING

use Data::Object::Base;

can_ok 'Data::Object::Base', 'space';

ok 1 and done_testing;
