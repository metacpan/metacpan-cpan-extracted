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

=libraries

Data::Object::Library

=description

This package modifies the consuming package making it a role, and is used to
allow you to specify rules for the consuming class. There is functionally no
difference between a role and a rule, so this concept only exists to
differentiate between that which describes an interface (rules) and that which
mixes-in behaviors.

=headers

+=head1 KEYWORDS

This package provides the following keywords.

+=head2 has

  package Person;

  use Data::Object 'Class';

  has fname => (
    is => 'ro',
    isa => 'Str'
  );

  has lname => (
    is => 'ro',
    isa => 'Str'
  );

  1;

The C<has> keyword is used to declare class attributes, which can be accessed
and assigned to using the built-in getter/setter or by the object constructor.
See L<Moo> for more information.

+=head2 with

  package Person;

  use Data::Object 'Class';

  with 'Employable';

  1;

The C<with> keyword is used to declare roles to be used and compose into your
role. See L<Moo> for more information.

=cut

use_ok "Data::Object::Rule";

ok 1 and done_testing;
