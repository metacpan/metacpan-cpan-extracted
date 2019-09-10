use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

DoCli

=usage

  Data::Object::Library::DoCli();

=description

This function returns the type configuration for a L<Data::Object::Cli>
object.

=signature

DoCli() : HashRef

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "DoCli";

ok 1 and done_testing;
