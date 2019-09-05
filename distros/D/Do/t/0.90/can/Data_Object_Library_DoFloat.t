use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoFloat

=usage

  Data::Object::Library::DoFloat();

=description

This function returns the type configuration for a L<Data::Object::Float>
object.

=signature

DoFloat() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoFloat";

ok 1 and done_testing;
