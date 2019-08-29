use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeException

=usage

  # given ...

  Data::Object::Utility::TypeException(...);

=description

The C<TypeException> function returns a L<Data::Object::Exception> instance
which can be thrown.

=signature

TypeException(Any @args) : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeException";

ok 1 and done_testing;
