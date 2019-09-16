use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoStashable

=usage

  Data::Object::Library::DoStashable();

=description

This function returns the type configuration for an object with the
L<Data::Object::Role::Stashable> role.

=signature

DoStashable() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoStashable";

ok 1 and done_testing;
