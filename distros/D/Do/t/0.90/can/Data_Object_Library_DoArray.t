use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoArray

=usage

  Data::Object::Library::DoArray();

=description

This function returns the type configuration for a L<Data::Object::Array>
object.

=signature

DoArray() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoArray";

ok 1 and done_testing;
