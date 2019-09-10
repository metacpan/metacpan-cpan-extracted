use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoData

=usage

  Data::Object::Library::DoData();

=description

This function returns the type configuration for a L<Data::Object::Data>
object.

=signature

DoData() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoData";

ok 1 and done_testing;
