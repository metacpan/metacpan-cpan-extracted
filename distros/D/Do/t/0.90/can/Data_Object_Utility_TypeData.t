use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeData

=usage

  # given ...

  Data::Object::Utility::TypeData(...);

=description

The C<TypeData> function returns a L<Data::Object::Data> instance which parses
pod-ish data in files and packages.

=signature

TypeData(Str $arg1) : Object

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeData";

ok 1 and done_testing;
