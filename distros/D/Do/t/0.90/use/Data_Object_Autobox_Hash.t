use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox::Hash

=abstract

Data-Object Autoboxing for Hash Objects

=synopsis

  use Data::Object::Autobox::Hash;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Hash> objects.

=cut

use_ok "Data::Object::Autobox::Hash";

ok 1 and done_testing;
