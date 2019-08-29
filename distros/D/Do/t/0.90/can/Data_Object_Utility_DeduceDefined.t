use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceDefined

=usage

  # given ...

  Data::Object::Utility::DeduceDefined(...);

=description

The C<DeduceDefined> function returns truthy if the argument is defined.

=signature

DeduceDefined(Any $arg1) : Int

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceDefined";

ok 1 and done_testing;
