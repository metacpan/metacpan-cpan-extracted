use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeDispatch

=usage

  # given ...

  Data::Object::Utility::TypeDispatch(...);

=description

The C<TypeDispatch> function return a L<Data::Object::Dispatch> object which is
a handle that let's you call into other packages.

=signature

TypeDispatch(Str $arg1) : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeDispatch";

ok 1 and done_testing;
