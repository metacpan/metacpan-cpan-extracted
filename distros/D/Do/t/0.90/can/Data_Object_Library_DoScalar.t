use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoScalar

=usage

  Data::Object::Library::DoScalar();

=description

This function returns the type configuration for a L<Data::Object::Scalar>
object.

=signature

DoScalar() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoScalar";

ok 1 and done_testing;
