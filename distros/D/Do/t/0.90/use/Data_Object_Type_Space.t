use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Space

=abstract

Data-Object Space Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Space;

  register Data::Object::Type::Space;

  1;

=description

Type constraint for validating L<Data::Object::Space> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Space";

ok 1 and done_testing;
