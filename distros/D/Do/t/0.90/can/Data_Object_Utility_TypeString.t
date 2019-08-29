use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeString

=usage

  # given ...

  Data::Object::Utility::TypeString(...);

=description

The C<TypeString> function returns a L<Data::Object::String> instance which
wraps the provided data type and can be used to perform operations on the data.

=signature

TypeString(Str $arg1) : StrObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeString";

ok 1 and done_testing;
