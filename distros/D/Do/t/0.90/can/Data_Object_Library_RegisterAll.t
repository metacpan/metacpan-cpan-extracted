use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

RegisterAll

=usage

  Data::Object::Library::RegisterAll({...});

=description

This function takes a type configuration hashref, then generates and returns a
L<Type::Tiny> object based on its configuration. This method also registers
aliases as stand-alone types in the library.

=signature

RegisterAll(HashRef $config) : InstanceOf["Type::Tiny"]

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "RegisterAll";

ok 1 and done_testing;
