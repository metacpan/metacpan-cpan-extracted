use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

deduce

=usage

  # given $arrayref

  my $array_object = $self->deduce($arrayref);

=description

The deduce method returns a data object for a given argument. A blessed
argument will be ignored, less a RegexpRef.

=signature

deduce(Maybe[Any] $arg) : Object

=type

method

=cut

# TESTING

use Data::Object::Base;

can_ok "Data::Object::Base", "deduce";

ok 1 and done_testing;
