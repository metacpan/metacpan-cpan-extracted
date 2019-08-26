use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Class

=abstract

Data-Object Class Declaration

=synopsis

  package Person;

  use Data::Object::Class;

  extends 'Identity';

  1;

=description

This package modifies the consuming package making it a L<Moo> class.

=cut

use_ok "Data::Object::Class";

ok 1 and done_testing;
