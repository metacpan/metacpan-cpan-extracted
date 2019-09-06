use 5.014;

use strict;
use warnings;

use Test::More;

=name

Data::Object::Rule::Collection

=abstract

Data-Object Collection Rules

=synopsis

  use Data::Object::Class;

  with 'Data::Object::Rule::Collection';

=libraries

Data::Object::Library

=description

This rule enforces the criteria for being a collection.

=cut

use_ok "Data::Object::Rule::Collection";

ok 1 and done_testing;
