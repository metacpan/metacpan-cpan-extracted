use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeCode

=usage

  # given ...

  Data::Object::Utility::TypeCode(...);

=description

The C<TypeCode> function returns a L<Data::Object::Code> instance which wraps
the provided data type and can be used to perform operations on the data.

=signature

TypeCode(CodeRef $arg1) : CodeObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeCode";

ok 1 and done_testing;
