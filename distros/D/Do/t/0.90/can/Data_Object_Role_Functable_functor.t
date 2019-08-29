use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

functor

=usage

  # given "delete"

  my $func = $self->functor('delete'); # bless('...', '...Func::Delete')

=description

The functor method return a functor, i.e. a function class, whose namespace is
based on the calling class and the argument provided. If the functor can be
loaded this method will return its fully-qualified name, otherwise it will
return empty.

=signature

functor(Str $name) : Maybe[Str]

=type

method

=cut

# TESTING

use Data::Object::Role::Functable;

can_ok "Data::Object::Role::Functable", "functor";

ok 1 and done_testing;
