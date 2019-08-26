use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

first

=usage

  # given [1..5]

  $array->first; # 1

=description

The first method returns the value of the first element in the array. This
method returns a data type object to be determined after execution.

=signature

first() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->first(), 2;

ok 1 and done_testing;
