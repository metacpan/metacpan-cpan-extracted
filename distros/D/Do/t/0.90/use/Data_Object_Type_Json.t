use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Json

=abstract

Data-Object Json Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Json;

  register Data::Object::Type::Json;

  1;

=description

Type constraint for validating L<Data::Object::Json> objects. This type
constraint is registered in the L<Data::Object::Library> type library. This
package inherits all behavior from L<Data::Object::Type>.

=cut

use_ok "Data::Object::Type::Json";

ok 1 and done_testing;
