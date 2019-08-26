use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Code

=abstract

Data-Object Code Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Code;

  register Data::Object::Type::Code;

  1;

=description

Type constraint for validating L<Data::Object::Code> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Code";

ok 1 and done_testing;
