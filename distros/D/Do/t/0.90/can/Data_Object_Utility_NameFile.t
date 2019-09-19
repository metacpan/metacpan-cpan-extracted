use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

NameFile

=usage

  # given ...

  Data::Object::Utility::NameFile(...);

=description

The C<NameFile> function returns the file representation for a given string.

=signature

NameFile(Str $arg1) : Str

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "NameFile";

ok 1 and done_testing;
