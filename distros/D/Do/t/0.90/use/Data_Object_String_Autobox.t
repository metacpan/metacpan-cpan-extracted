use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::String::Autobox

=abstract

Data-Object Autoboxing for String Objects

=synopsis

  use Data::Object::String::Autobox;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::String> objects.

=cut

use_ok "Data::Object::String::Autobox";

ok 1 and done_testing;
