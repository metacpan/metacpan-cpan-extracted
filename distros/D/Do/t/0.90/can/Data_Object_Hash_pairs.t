use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

pairs

=usage

  # given {1..8}

  $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]

=description

The pairs method is an alias to the pairs_array method. This method returns a
L<Data::Object::Array> object. This method is an alias to the pairs_array
method.

=signature

pairs() : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->pairs(), [[1,2],[3,4],[5,6],[7,8]];

ok 1 and done_testing;
