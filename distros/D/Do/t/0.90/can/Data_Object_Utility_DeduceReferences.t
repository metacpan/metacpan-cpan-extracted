use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DeduceReferences

=usage

  # given ...

  Data::Object::Utility::DeduceReferences(...);

=description

The C<DeduceReferences> function returns a data object based on the type of
argument reference provided.

=signature

DeduceReferences(Any $arg1) : Int

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "DeduceReferences";

ok 1 and done_testing;
