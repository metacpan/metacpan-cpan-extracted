use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

data_integer

=usage

  # given -100;

  $object = data_integer -100;
  $object->isa('Data::Object::Integer');

=description

The data_integer function returns a L<Data::Object::Object> instance which wraps
the provided data type and can be used to perform operations on the data. The
C<type_integer> function is an alias to this function.

=signature

data_integer(Int $arg1) : IntObject

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'data_integer';

ok 1 and done_testing;
