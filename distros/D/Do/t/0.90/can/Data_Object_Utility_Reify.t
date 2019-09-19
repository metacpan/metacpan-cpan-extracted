use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Reify

=usage

  # given ...

  Data::Object::Utility::Reify(...);

=description

The C<Reify> function returns a type constraint for a given namespace and
expression.

=signature

Reify(Str $namespace, Str $expression) : Maybe[Object]

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Reify";

ok 1 and done_testing;
