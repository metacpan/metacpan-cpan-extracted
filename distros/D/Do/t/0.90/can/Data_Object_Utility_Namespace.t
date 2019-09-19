use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Namespace

=usage

  # given ...

  Data::Object::Utility::Namespace(...);

=description

The C<Namespace> function registers a type library with a namespace in the
registry so that typed operations know where to look for type context-specific
constraints.

=signature

Namespace(Str $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "Namespace";

ok 1 and done_testing;
