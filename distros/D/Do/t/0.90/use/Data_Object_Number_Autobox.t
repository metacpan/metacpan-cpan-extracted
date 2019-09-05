use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Number::Autobox

=abstract

Data-Object Number Class Autoboxing

=synopsis

  use Data::Object::Number::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Number> objects.

+=head1 ROLES

This package assumes all behavior from the follow roles:

L<Data::Object::Role::Proxyable>

=cut

use_ok "Data::Object::Number::Autobox";

ok 1 and done_testing;
