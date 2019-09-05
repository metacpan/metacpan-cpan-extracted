use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoFunc

=usage

  Data::Object::Library::DoFunc();

=description

This function returns the type configuration for a L<Data::Object::Func>
object.

=signature

DoFunc() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoFunc";

ok 1 and done_testing;
