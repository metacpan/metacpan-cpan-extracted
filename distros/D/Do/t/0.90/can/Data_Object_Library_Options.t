use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

Options

=usage

  Data::Object::Library::Options({...});

=description

This function takes a type configuration hashref, then generates and returns a
set of options relevant to creating L<Type::Tiny> objects.

=signature

Options(HashRef $config) : (Any)

=type

function

=cut

# TESTING

use Data::Object::Library;

can_ok "Data::Object::Library", "Options";

ok 1 and done_testing;
