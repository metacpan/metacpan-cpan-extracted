use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each

=usage

  # given ['a'..'g']

  $array->each(fun ($index, $value) {
      ...
  });

=description

The each method iterates over each element in the array, executing the code
reference supplied in the argument, passing the routine the index and value at
the current position in the loop. This method returns a L<Data::Object::Array>
object.

=signature

each(CodeRef $arg1, Any @args) : Object

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['a'..'g']);

is_deeply $data->each(sub { [@_] }), $data;

ok 1 and done_testing;
