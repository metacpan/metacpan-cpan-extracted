use 5.014;

use strict;
use warnings;

use Test::More;

=name

Doodle

=abstract

Doodle Type Library

=synopsis

  use Doodle::Library;

=description

Doodle::Library is the L<Doodle> type library derived from
L<Data::Object::Library> which is a L<Type::Library>

=cut

use_ok "Doodle::Library";

isa_ok "Doodle::Library", "Type::Library";

ok 1 and done_testing;
