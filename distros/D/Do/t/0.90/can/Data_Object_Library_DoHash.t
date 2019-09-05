use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoHash

=usage

  Data::Object::Library::DoHash();

=description

This function returns the type configuration for a L<Data::Object::Hash>
object.

=signature

DoHash() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoHash";

ok 1 and done_testing;
