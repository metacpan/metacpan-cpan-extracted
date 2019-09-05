use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Register

=usage

  Data::Object::Library::Register({...});

=description

This function takes a type configuration hashref, then generates and returns a
L<Type::Tiny> object based on its configuration.

=signature

Register(HashRef $config) : InstanceOf["Type::Tiny"]

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "Register";

ok 1 and done_testing;
