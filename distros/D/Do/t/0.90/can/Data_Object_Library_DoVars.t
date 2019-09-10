use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoVars

=usage

  Data::Object::Library::DoVars();

=description

This function returns the type configuration for a L<Data::Object::Vars>
object.

=signature

DoVars() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoVars";

ok 1 and done_testing;
