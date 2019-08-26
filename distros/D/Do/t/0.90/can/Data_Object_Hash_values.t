use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

values

=usage

  # given {1..8}

  $hash->values; # [2,4,6,8]
  $hash->values(1,3); # [2,4]

=description

The values method returns an array reference consisting of the values of the
elements in the hash. This method returns a L<Data::Object::Array> object.

=signature

values(Str $arg1) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply [sort @{$data->values()}], [2,4,6,8];

is_deeply $data->values(1,3), [2,4];

ok 1 and done_testing;
