use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::List

=abstract

Data-Object List Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::List';

=description

This rule enforces the criteria for being mapable (i.e. a list, capabile of
being iterated over).

=cut

use_ok "Data::Object::Rule::List";

ok 1 and done_testing;
