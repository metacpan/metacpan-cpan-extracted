use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Undef::Autobox

=abstract

Data-Object Autoboxing for Undef Objects

=synopsis

  use Data::Object::Undef::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Undef> objects.

=cut

use_ok "Data::Object::Undef::Autobox";

ok 1 and done_testing;
