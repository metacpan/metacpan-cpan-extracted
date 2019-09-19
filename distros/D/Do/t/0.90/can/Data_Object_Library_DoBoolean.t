use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoBoolean

=usage

  Data::Object::Library::DoBoolean();

=description

This function returns the type configuration for a L<Data::OBject::Code>
object.

=signature

DoBoolean() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoBoolean";

ok 1 and done_testing;
