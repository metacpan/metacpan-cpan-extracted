use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeScalar

=usage

  # given ...

  Data::Object::Utility::TypeScalar(...);

=description

The C<TypeScalar> function returns a L<Data::Object::Scalar> instance which
wraps the provided data type and can be used to perform operations on the data.

=signature

TypeScalar(Any $arg1) : ScalarObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeScalar";

ok 1 and done_testing;
