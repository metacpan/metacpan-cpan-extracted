use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoDumpable

=usage

  Data::Object::Library::DoDumpable();

=description

This function returns the type configuration for an object with the
L<Data::Object::Role::Dumpable> role.

=signature

DoDumpable() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoDumpable";

ok 1 and done_testing;
