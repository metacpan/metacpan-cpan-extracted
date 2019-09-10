use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoState

=usage

  Data::Object::Library::DoState();

=description

This function returns the type configuration for a L<Data::Object::State>
object.

=signature

DoState() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoState";

ok 1 and done_testing;
