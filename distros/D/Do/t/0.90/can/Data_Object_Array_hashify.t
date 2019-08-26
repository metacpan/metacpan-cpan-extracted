use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

hashify

=usage

  # given [1..5]

  $array->hashify; # {1=>1,2=>1,3=>1,4=>1,5=>1}
  $array->hashify(fun ($value) { $value % 2 }); # {1=>1,2=>0,3=>1,4=>0,5=>1}

=description

The hashify method returns a hash reference where the elements of array become
the hash keys and the corresponding values are assigned a value of 1. This
method returns a L<Data::Object::Hash> object.

=signature

hashify(CodeRef $arg1, Any $arg2) : HashObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([1..5]);

is_deeply $data->hashify(), {1=>1,2=>1,3=>1,4=>1,5=>1};

is_deeply $data->hashify(sub { $_[0] % 2 }), {1=>1,2=>0,3=>1,4=>0,5=>1};

ok 1 and done_testing;
