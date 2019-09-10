use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoStruct

=usage

  Data::Object::Library::DoStruct();

=description

This function returns the type configuration for a L<Data::Object::Struct>
object.

=signature

DoStruct() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoStruct";

ok 1 and done_testing;
