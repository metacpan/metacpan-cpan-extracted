use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Undef

=abstract

Data-Object Undef Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Undef;

  register Data::Object::Type::Undef;

  1;

=description

Type constraint for validating L<Data::Object::Undef> objects. This type
constraint is registered in the L<Data::Object::Library> type library.

=cut

use_ok "Data::Object::Type::Undef";

ok 1 and done_testing;
