use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Detract

=abstract

Data-Object Detract Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Detract';

=description

This role provides functionality for accessing the underlying data type and
value.

=cut

use_ok "Data::Object::Role::Detract";

ok 1 and done_testing;
