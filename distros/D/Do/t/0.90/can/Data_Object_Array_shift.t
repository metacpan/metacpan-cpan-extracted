use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

shift

=usage

  # given [1..5]

  $array->shift; # 1

=description

The shift method returns the first element of the array shortening it by one.
This method returns a data type object to be determined after execution. Note:
This method modifies the array.

=signature

shift() : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->shift(), 1;

ok 1 and done_testing;
