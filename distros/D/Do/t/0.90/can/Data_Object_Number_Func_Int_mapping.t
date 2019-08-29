use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

mapping

=usage

  my @data = $self->mapping;

=description

Returns the ordered list of named function object arguments.

=signature

mapping() : (Str)

=type

method

=cut

# TESTING

use Data::Object::Number::Func::Int;

can_ok "Data::Object::Number::Func::Int", "mapping";

my @data;

@data = Data::Object::Number::Func::Int->mapping();

is @data, 1;

is $data[0], 'arg1';

ok 1 and done_testing;
