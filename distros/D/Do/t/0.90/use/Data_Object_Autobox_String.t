use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox::String

=abstract

Data-Object Autoboxing for String Objects

=synopsis

  use Data::Object::Autobox::String;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::String> objects.

=cut

use_ok "Data::Object::Autobox::String";

ok 1 and done_testing;
