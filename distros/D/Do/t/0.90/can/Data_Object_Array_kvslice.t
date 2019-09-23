use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

slice

=usage

  # given [1..5]

  $array->kvslice(2,4); # {2=>3, 4=>5}

=description

The kvslice method returns a hash reference containing the elements in the
array at the index(es) specified in the arguments. This method returns a
L<Data::Object::Hash> object.

=signature

kvslice(Any @args) : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->kvslice(2,4), {2=>3, 4=>5};

ok 1 and done_testing;
