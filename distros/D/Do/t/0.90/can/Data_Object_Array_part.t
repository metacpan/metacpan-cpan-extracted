use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

part

=usage

  # given [1..10]

  $array->part(fun ($value) { $value > 5 }); # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]

=description

The part method iterates over each element in the array, executing the code
reference supplied in the argument, using the result of the code reference to
partition to array into two distinct array references. This method returns an
array reference containing exactly two array references. This method returns a
L<Data::Object::Array> object.

=signature

part(CodeRef $arg1, Any $arg2) : Tuple[ArrayRef, ArrayRef]

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..10]);

is_deeply $data->part(sub { shift > 5 }), [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]];

ok 1 and done_testing;
