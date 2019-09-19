use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

NamePackage

=usage

  # given ...

  Data::Object::Utility::NamePackage(...);

=description

The C<NamePackage> function returns the package representation for a give
string.

=signature

NamePackage(Str $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "NamePackage";

ok 1 and done_testing;
