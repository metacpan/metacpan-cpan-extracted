use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Autobox::Undef

=abstract

Data-Object Autoboxing for Undef Objects

=synopsis

  use Data::Object::Autobox::Undef;

=description

This package implements autoboxing via L<Data::Object::Autobox> for
L<Data::Object::Undef> objects.

=cut

use_ok "Data::Object::Autobox::Undef";

ok 1 and done_testing;
