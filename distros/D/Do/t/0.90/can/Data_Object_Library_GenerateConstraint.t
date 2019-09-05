use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

GenerateConstraint

=usage

  Data::Object::Library::GenerateConstraint({...});

=description

This function takes a type configuration hashref, then generates and returns a
coderef which validates the type based on its configuration.

=signature

GenerateConstraint(HashRef $config) : CodeRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "GenerateConstraint";

ok 1 and done_testing;
