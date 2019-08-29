use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeSpace

=usage

  # given ...

  Data::Object::Utility::TypeSpace(...);

=description

The C<TypeSpace> function returns a L<Data::Object::Space> instance which
provides methods for operating on package and namespaces.

=signature

TypeSpace(Str $arg1) : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeSpace";

ok 1 and done_testing;
