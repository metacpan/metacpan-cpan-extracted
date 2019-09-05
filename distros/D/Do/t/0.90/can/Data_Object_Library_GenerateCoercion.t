use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

GenerateCoercion

=usage

  Data::Object::Library::GenerateCoercion({...});

=description

This function takes a type configuration hashref, then generates and returns a
type coercion based on its configuration.

=signature

GenerateCoercion(HashRef $config) : InstanceOf["Type::Coercion"]

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "GenerateCoercion";

ok 1 and done_testing;
