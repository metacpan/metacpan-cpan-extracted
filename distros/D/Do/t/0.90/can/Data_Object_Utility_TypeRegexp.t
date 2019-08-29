use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

TypeRegexp

=usage

  # given ...

  Data::Object::Utility::TypeRegexp(...);

=description

The C<TypeRegexp> function returns a L<Data::Object::Regexp> instance which
wraps the provided data type and can be used to perform operations on the data.

=signature

TypeRegexp(RegexpRef $arg1) : RegexpObject

=type

function

=cut

# TESTING

use Data::Object::Utility;

can_ok "Data::Object::Utility", "TypeRegexp";

ok 1 and done_testing;
