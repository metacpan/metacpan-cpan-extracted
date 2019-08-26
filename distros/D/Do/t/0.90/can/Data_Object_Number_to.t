use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

to

=usage

  # given 5

  $number->to(9); # [5,6,7,8,9]
  $number->to(1); # [5,4,3,2,1]

=description

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object. This method returns a
L<Data::Object::Array> object.

=signature

to(Int $arg1) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Number';

my $data = Data::Object::Number->new(12);

is_deeply $data->to(6), [12,11,10,9,8,7,6];

is_deeply $data->to(18), [12,13,14,15,16,17,18];

ok 1 and done_testing;
