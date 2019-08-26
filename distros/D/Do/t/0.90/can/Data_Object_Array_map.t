use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

map

=usage

  # given [1..5]

  $array->map(sub{
      shift + 1
  });

  # [2,3,4,5,6]

=description

The map method iterates over each element in the array, executing the
code reference supplied in the argument, passing the routine the value at the
current position in the loop and returning a new array reference containing
the elements for which the argument returns a value or non-empty list. This
method returns a L<Data::Object::Array> object.

=signature

map(CodeRef $arg1, Any $arg2) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->map(sub { $_[0] + 1 }), [2,3,4,5,6];

ok 1 and done_testing;
