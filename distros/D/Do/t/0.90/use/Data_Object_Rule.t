use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule

=abstract

Data-Object Rule Declaration

=synopsis

  package Persona;

  use Data::Object::Rule;

  requires 'id';
  requires 'fname';
  requires 'lname';
  requires 'created';
  requires 'updated';

  1;

=inherits

Moo::Role

=description

This package modifies the consuming package making it a L<Moo> role, and is
used to allow you to specify rules for the consuming class. There is
functionally no difference between a role and a rule, so this concept only
exists to differentiate between that which describes an interface (rules) and
that which mixes-in behaviors.

=cut

use_ok "Data::Object::Rule";

ok 1 and done_testing;
