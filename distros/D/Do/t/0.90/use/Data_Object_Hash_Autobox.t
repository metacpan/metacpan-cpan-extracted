use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Hash::Autobox

=abstract

Data-Object Autoboxing for Hash Objects

=synopsis

  use Data::Object::Hash::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Hash> objects.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Hash::Autobox";

ok 1 and done_testing;
