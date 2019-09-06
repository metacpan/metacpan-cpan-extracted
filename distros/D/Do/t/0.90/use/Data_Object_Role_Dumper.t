use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Dumper

=abstract

Data-Object Dumper Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Dumper';

=libraries

Data::Object::Library

=description

This role provides functionality for dumping the object and underlying value.

=cut

use_ok "Data::Object::Role::Dumper";

ok 1 and done_testing;
