use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox::Scalar

=abstract

Data-Object Autoboxing for Scalar Objects

=synopsis

  use Data::Object::Autobox::Scalar;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Scalar> objects.

=cut

use_ok "Data::Object::Autobox::Scalar";

ok 1 and done_testing;
