use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeName

=usage

  # given ...

  Data::Object::Utility::TypeName(...);

=description

The C<TypeName> function returns a data type description for the type of data
provided, represented as a string in capital letters.

=signature

TypeName(Any $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeName";

ok 1 and done_testing;
