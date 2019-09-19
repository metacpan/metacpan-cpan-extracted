use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

NamePath

=usage

  # given ...

  Data::Object::Utility::NamePath(...);

=description

The C<NamePath> function returns the path representation for a given string.

=signature

NamePath(Str $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "NamePath";

ok 1 and done_testing;
