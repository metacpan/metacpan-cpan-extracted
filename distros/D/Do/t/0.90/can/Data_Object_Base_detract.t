use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

detract

=usage

  # given $array_object

  my $arrayref = $self->detract($array_object);

=description

The detract method returns a raw data value for a given argument which is a
type of data object. If no argument is provided the invocant will be used.

=signature

detract(Maybe[Any] $arg) : Value

=type

method

=cut

# TESTING

use Data::Object::Base;

can_ok "Data::Object::Base", "detract";

ok 1 and done_testing;
