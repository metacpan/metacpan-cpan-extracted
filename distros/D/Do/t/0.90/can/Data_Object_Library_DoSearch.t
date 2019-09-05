use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoSearch

=usage

  Data::Object::Library::DoSearch();

=description

This function returns the type configuration for a L<Data::Object::Search>
object.

=signature

DoSearch() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoSearch";

ok 1 and done_testing;
