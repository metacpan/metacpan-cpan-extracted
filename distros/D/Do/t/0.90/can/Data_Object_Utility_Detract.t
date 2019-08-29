use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Detract

=usage

  # given ...

  Data::Object::Utility::Detract(...);

=description

The C<Detract> function returns a value of native type, based upon the
underlying reference of the data type object provided.

=signature

Detract(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Detract";

ok 1 and done_testing;
