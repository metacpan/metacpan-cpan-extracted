use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoUndef

=usage

  Data::Object::Library::DoUndef();

=description

This function returns the type configuration for a L<Data::Object::Undef>
object.

=signature

DoUndef() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoUndef";

ok 1 and done_testing;
