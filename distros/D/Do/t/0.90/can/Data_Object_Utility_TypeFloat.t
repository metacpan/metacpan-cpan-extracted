use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeFloat

=usage

  # given ...

  Data::Object::Utility::TypeFloat(...);

=description

The C<TypeFloat> function returns a L<Data::Object::Float> instance which wraps
the provided data type and can be used to perform operations on the data.

=signature

TypeFloat(Str $arg1) : FloatObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeFloat";

ok 1 and done_testing;
