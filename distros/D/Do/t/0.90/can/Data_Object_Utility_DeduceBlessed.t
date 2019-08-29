use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceBlessed

=usage

  # given ...

  Data::Object::Utility::DeduceBlessed(...);

=description

The C<DeduceBlessed> function returns truthy if the argument is blessed.

=signature

DeduceBlessed(Any $arg1) : Int

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceBlessed";

ok 1 and done_testing;
