use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoOpts

=usage

  Data::Object::Library::DoOpts();

=description

This function returns the type configuration for a L<Data::Object::Opts>
object.

=signature

DoOpts() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoOpts";

ok 1 and done_testing;
