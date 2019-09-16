use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoImmutable

=usage

  Data::Object::Library::DoImmutable();

=description

This function returns the type configuration for an object with the
L<Data::Object::Role::Immutable> role.

=signature

DoImmutable() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoImmutable";

ok 1 and done_testing;
