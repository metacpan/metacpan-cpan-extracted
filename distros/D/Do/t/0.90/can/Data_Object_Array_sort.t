use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

sort

=usage

  # given ['d','c','b','a']

  $array->sort; # ['a','b','c','d']

=description

The sort method returns an array reference containing the values in the array
sorted alphanumerically. This method returns a L<Data::Object::Array> object.

=signature

sort() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new(['d','c','b','a']);

is_deeply $data->sort(), ['a','b','c','d'];

ok 1 and done_testing;
