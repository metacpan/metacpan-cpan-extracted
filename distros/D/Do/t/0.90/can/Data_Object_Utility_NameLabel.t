use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

NameLabel

=usage

  # given ...

  Data::Object::Utility::NameLabel(...);

=description

The C<NameLabel> function returns the label representation for a given string.

=signature

NameLabel(Str $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "NameLabel";

ok 1 and done_testing;
