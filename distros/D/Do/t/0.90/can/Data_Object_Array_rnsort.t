use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

rnsort

=usage

  # given [5,4,3,2,1]

  $array->rnsort; # [5,4,3,2,1]

=description

The rnsort method returns an array reference containing the values in the
array sorted numerically in reverse. This method returns a
L<Data::Object::Array> object.

=signature

rnsort() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([5,4,3,2,1]);

is_deeply $data->rnsort(), [5,4,3,2,1];

ok 1 and done_testing;
