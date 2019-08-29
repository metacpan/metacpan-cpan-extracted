use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceNumberlike

=usage

  # given ...

  Data::Object::Utility::DeduceNumberlike(...);

=description

The C<DeduceNumberlike> function returns truthy if the argument is numberlike.

=signature

DeduceNumberlike(Any $arg1) : Int

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceNumberlike";

ok 1 and done_testing;
