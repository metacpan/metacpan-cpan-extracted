use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceStringLike

=usage

  # given ...

  Data::Object::Utility::DeduceStringLike(...);

=description

The C<DeduceStringLike> function returns truthy if the argument is stringlike.

=signature

DeduceStringLike(Any $arg1) : Int

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceStringLike";

ok 1 and done_testing;
