use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

new

=usage

  my $scalar = Data::Object::Autobox::Scalar->new(\*main);

=description

Construct a new object.

=signature

new(Any $arg1) : ScalarObject

=type

method

=cut

# TESTING

use Data::Object::Autobox::Scalar;

can_ok "Data::Object::Autobox::Scalar", "new";

ok 1 and done_testing;
