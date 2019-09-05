use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoNumber

=usage

  Data::Object::Library::DoNumber();

=description

This function returns the type configuration for a L<Data::Object::Number>
object.

=signature

DoNumber() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoNumber";

ok 1 and done_testing;
