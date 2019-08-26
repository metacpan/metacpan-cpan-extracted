use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

push

=usage

  # given [1..5]

  $array->push(6,7,8); # [1,2,3,4,5,6,7,8]

=description

The push method appends the array by pushing the agruments onto it and returns
itself. This method returns a data type object to be determined after execution.
Note: This method modifies the array.

=signature

push(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->push(6,7,8), [1,2,3,4,5,6,7,8];

ok 1 and done_testing;
