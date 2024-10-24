use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::Comparison

=abstract

Data-Object Comparison Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::Comparison';

=libraries

Data::Object::Library

=description

This rule enforces the criteria for being comparable.

=cut

use_ok "Data::Object::Rule::Comparison";

ok 1 and done_testing;
