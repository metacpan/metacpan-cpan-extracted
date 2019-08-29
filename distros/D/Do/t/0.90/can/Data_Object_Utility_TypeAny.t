use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeAny

=usage

  # given ...

  Data::Object::Utility::TypeAny(...);

=description

The C<TypeAny> function returns a L<Data::Object::Any> instance which wraps the
provided data type and can be used to perform operations on the data.

=signature

TypeAny(Any $arg1) : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeAny";

ok 1 and done_testing;
