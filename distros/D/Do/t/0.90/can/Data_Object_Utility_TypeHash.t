use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeHash

=usage

  # given ...

  Data::Object::Utility::TypeHash(...);

=description

The C<TypeHash> function returns a L<Data::Object::Hash> instance which wraps
the provided data type and can be used to perform operations on the data.

=signature

TypeHash(HashRef $arg1) : HashObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeHash";

ok 1 and done_testing;
