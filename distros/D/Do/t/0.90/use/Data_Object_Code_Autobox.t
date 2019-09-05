use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Code::Autobox

=abstract

Data-Object Code Class Autoboxing

=synopsis

  use Data::Object::Code::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Code> objects.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Code::Autobox";

ok 1 and done_testing;
