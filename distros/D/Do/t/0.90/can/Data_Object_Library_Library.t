use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Library

=usage

  Data::Object::Library::Library();

=description

This function returns the core type library object.

=signature

Library() : InstanceOf["Type::Library"]

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "Library";

ok 1 and done_testing;
