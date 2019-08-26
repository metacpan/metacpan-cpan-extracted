use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Hash

=abstract

Data-Object Hash Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Hash;

  register Data::Object::Type::Hash;

  1;

=description

Type constraint for validating L<Data::Object::Hash> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Hash";

ok 1 and done_testing;
