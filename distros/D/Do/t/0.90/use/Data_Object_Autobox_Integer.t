use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox::Integer

=abstract

Data-Object Autoboxing for Integer Objects

=synopsis

  use Data::Object::Autobox::Integer;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Integer> objects.

=cut

use_ok "Data::Object::Autobox::Integer";

ok 1 and done_testing;
