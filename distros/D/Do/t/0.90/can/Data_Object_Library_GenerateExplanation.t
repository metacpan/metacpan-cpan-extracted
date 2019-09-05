use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

GenerateExplanation

=usage

  Data::Object::Library::GenerateExplanation({...});

=description

This function takes a type configuration hashref, then generates and returns a
coderef which returns a deep-explanation of the type failure based on its
configuration.

=signature

GenerateExplanation(HashRef $config) : CodeRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "GenerateExplanation";

ok 1 and done_testing;
