use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

length

=usage

  # given [1..5]

  $array->length; # 5

=description

The length method returns the number of elements in the array. This method
returns a L<Data::Object::Number> object.

=signature

length() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->length(), 5;

ok 1 and done_testing;
