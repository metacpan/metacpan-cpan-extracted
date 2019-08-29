use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Scalar::Autobox

=abstract

Data-Object Autoboxing for Scalar Objects

=synopsis

  use Data::Object::Scalar::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Scalar> objects.

=cut

use_ok "Data::Object::Scalar::Autobox";

ok 1 and done_testing;
