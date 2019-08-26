use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Role

=abstract

Data-Object Role Declaration

=synopsis

  package Persona;

  use Data::Object::Role;

  with 'Relatable';

  1;

=description

This package modifies the consuming package making it a L<Moo> role.

=cut

use_ok "Data::Object::Role";

ok 1 and done_testing;
