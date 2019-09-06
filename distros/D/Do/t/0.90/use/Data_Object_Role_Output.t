use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Output

=abstract

Data-Object Output Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Output';

=libraries

Data::Object::Library

=description

This package provides mechanisms for printing the object.

=cut

use_ok "Data::Object::Role::Output";

ok 1 and done_testing;
