use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

sum

=usage

  # given [1..5]

  $array->sum; # 15

=description

The sum method returns the sum of all values for all numerical elements in the
array. All non-numerical element are skipped during the evaluation process. This
method returns a L<Data::Object::Number> object.

=signature

sum() : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->sum(), 15;

ok 1 and done_testing;
