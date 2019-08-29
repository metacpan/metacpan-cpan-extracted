use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeInteger

=usage

  # given ...

  Data::Object::Utility::TypeInteger(...);

=description

The C<TypeInteger> function returns a L<Data::Object::Object> instance which
wraps the provided data type and can be used to perform operations on the data.

=signature

TypeInteger(Int $arg1) : IntObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeInteger";

ok 1 and done_testing;
