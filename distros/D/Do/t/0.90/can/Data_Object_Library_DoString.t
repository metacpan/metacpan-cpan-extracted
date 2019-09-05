use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoString

=usage

  Data::Object::Library::DoString();

=description

This function returns the type configuration for a L<Data::Object::String>
object.

=signature

DoString() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoString";

ok 1 and done_testing;
