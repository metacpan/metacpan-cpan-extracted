use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoException

=usage

  Data::Object::Library::DoException();

=description

This function returns the type configuration for a L<Data::Object::Exception>
object.

=signature

DoException() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoException";

ok 1 and done_testing;
