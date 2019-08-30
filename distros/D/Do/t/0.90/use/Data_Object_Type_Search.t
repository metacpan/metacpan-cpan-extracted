use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Type::Search

=abstract

Data-Object Search Type Constraint

=synopsis

  package App::Type::Library;

  use Type::Library -base;

  use Data::Object::Type::Search;

  register Data::Object::Type::Search;

  1;

=description

Type constraint for validating L<Data::Object::Search> objects. This type
constraint is registered in the L<Data::Object::Library> type library. This
package inherits all behavior from L<Data::Object::Type>.

=cut

use_ok "Data::Object::Type::Search";

ok 1 and done_testing;
