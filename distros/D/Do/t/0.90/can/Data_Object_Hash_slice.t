use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

slice

=usage

  # given {1..8}

  $hash->slice(1,3); # [2,4]

=description

The slice method returns an array reference of the values that correspond to
the key(s) specified in the arguments. This method returns a
L<Data::Object::Array> object.

=signature

slice(Str @args) : ArrayObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->slice(1,3), [2,4];

ok 1 and done_testing;
