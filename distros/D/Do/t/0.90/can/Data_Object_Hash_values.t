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

=description

The values method returns an array reference consisting of the values of the
elements in the hash. This method returns a L<Data::Object::Array> object.

=signature

values() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply [sort { $a <=> $b } @{$data->values}], [2,4,6,8];

ok 1 and done_testing;
