use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::RoleHas

=abstract

Data-Object Role Attribute Builder

=synopsis

  package Pointable;

  use Data::Object::Role;
  use Data::Object::RoleHas;

  has 'x';
  has 'y';

  1;

=description

This package modifies the consuming package with behaviors useful in defining
classes. Specifically, this package wraps the C<has> attribute keyword
functions and adds shortcuts and enhancements.

=cut

use_ok "Data::Object::RoleHas";

ok 1 and done_testing;
