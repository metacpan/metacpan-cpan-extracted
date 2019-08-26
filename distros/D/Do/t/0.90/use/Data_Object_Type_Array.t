use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Array

=abstract

Data-Object Array Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Array;

  register Data::Object::Type::Array;

  1;

=description

Type constraint for validating L<Data::Object::Array> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Array";

ok 1 and done_testing;
