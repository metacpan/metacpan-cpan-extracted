use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceDeep

=usage

  # given ...

  Data::Object::Utility::DeduceDeep(...);

=description

The C<DeduceDeep> function returns a data type object. If the data provided is
complex, this function traverses the data converting all nested data to
objects. Note: Blessed objects are not traversed.

=signature

DeduceDeep(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceDeep";

ok 1 and done_testing;
