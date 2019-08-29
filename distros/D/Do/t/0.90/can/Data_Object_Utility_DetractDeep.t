use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DetractDeep

=usage

  # given ...

  Data::Object::Utility::DetractDeep(...);

=description

The C<DetractDeep> function returns a value of native type. If the data
provided is complex, this function traverses the data converting all nested
data type objects into native values using the objects underlying reference.
Note: Blessed objects are not traversed.

=signature

DetractDeep(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DetractDeep";

ok 1 and done_testing;
