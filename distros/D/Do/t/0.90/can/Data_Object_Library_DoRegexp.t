use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoRegexp

=usage

  Data::Object::Library::DoRegexp();

=description

This function returns the type configuration for a L<Data::Object::Regexp>
object.

=signature

DoRegexp() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoRegexp";

ok 1 and done_testing;
