use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoThrowable

=usage

  Data::Object::Library::DoThrowable();

=description

This function returns the type configuration for an object with the
L<Data::Object::Role::Throwable> role.

=signature

DoThrowable() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoThrowable";

ok 1 and done_testing;
