use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Dumpable

=abstract

Data-Object Dumpable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Dumpable';

=libraries

Data::Object::Library

=description

This role provides functionality for dumping the object and underlying value.

=cut

use_ok "Data::Object::Role::Dumpable";

ok 1 and done_testing;
