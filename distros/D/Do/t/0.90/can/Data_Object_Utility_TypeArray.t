use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeArray

=usage

  # given ...

  Data::Object::Utility::TypeArray(...);

=description

The C<TypeArray> function returns a L<Data::Object::Array> instance which wraps
the provided data type and can be used to perform operations on the data.

=signature

TypeArray(ArrayRef $arg1) : ArrayObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeArray";

ok 1 and done_testing;
