use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeNumber

=usage

  # given ...

  Data::Object::Utility::TypeNumber(...);

=description

The C<TypeNumber> function returns a L<Data::Object::Number> instance which
wraps the provided data type and can be used to perform operations on the data.

=signature

TypeNumber(Num $arg1) : NumObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeNumber";

ok 1 and done_testing;
