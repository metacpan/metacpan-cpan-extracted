use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Registry

=usage

  # given ...

  Data::Object::Utility::Registry(...);

=description

The C<Registry> function returns the global L<Data::Object::Registry> object,
which holds mappings between namespaces and type registries.

=signature

Registry() : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Registry";

ok 1 and done_testing;
