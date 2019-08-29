use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeUndef

=usage

  # given ...

  Data::Object::Utility::TypeUndef(...);

=description

The C<TypeUndef> function returns a L<Data::Object::Undef> instance which wraps
the provided data type and can be used to perform operations on the data.

=signature

TypeUndef(Undef $arg1) : UndefObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeUndef";

ok 1 and done_testing;
