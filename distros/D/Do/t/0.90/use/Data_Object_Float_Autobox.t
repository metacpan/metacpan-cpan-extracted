use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Float::Autobox

=abstract

Data-Object Autoboxing for Float Objects

=synopsis

  use Data::Object::Float::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Float> objects.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Float::Autobox";

ok 1 and done_testing;
