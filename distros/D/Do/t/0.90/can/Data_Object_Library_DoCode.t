use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoCode

=usage

  Data::Object::Library::DoCode();

=description

This function returns the type configuration for a L<Data::Object::Code>
object.

=signature

DoCode() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoCode";

ok 1 and done_testing;
