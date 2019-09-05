use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoReplace

=usage

  Data::Object::Library::DoReplace();

=description

This function returns the type configuration for a L<Data::Object::Replace>
object.

=signature

DoReplace() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoReplace";

ok 1 and done_testing;
