use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Number

=abstract

Data-Object Number Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Number;

  register Data::Object::Type::Number;

  1;

=description

Type constraint for validating L<Data::Object::Number> objects. This type
constraint is registered in the L<Data::Object::Library> type library. This
package inherits all behavior from L<Data::Object::Type>.

=cut

use_ok "Data::Object::Type::Number";

ok 1 and done_testing;
