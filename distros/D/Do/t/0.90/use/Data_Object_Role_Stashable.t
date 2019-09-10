use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role::Stashable

=abstract

Data-Object Stashable Role

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Role::Stashable';

=libraries

Data::Object::Library

=description

This role provides a pattern for stashing data related to the object.

=cut

use_ok "Data::Object::Role::Stashable";

ok 1 and done_testing;
