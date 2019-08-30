use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Integer::Autobox

=abstract

Data-Object Autoboxing for Integer Objects

=synopsis

  use Data::Object::Integer::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Integer> objects.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Integer::Autobox";

ok 1 and done_testing;
