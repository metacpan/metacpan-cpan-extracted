use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Deduce

=usage

  # given ...

  Data::Object::Utility::Deduce(...);

=description

The C<Deduce> function returns a data type object instance based upon the
deduced type of data provided.

=signature

Deduce(Any $arg1) : Any

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Deduce";

ok 1 and done_testing;
