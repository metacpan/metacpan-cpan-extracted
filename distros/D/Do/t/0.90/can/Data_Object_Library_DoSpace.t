use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoSpace

=usage

  Data::Object::Library::DoSpace();

=description

This function returns the type configuration for a L<Data::Object::Space>
object.

=signature

DoSpace() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoSpace";

ok 1 and done_testing;
