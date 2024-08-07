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

use Data::Object::Code::Func::Defined;

can_ok "Data::Object::Code::Func::Defined", "mapping";

my @data;

@data = Data::Object::Code::Func::Defined->mapping();

is @data, 1;

is $data[0], 'arg1';

ok 1 and done_testing;
