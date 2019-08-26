use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

each_n_values

=usage

  # given {1..8}

  $hash->each_n_values(4, fun (@values) {
      $values[1] # 2
      $values[2] # 4
      $values[3] # 6
      $values[4] # 8
      ...
  });

=description

The each_n_values method iterates over each element in the hash, executing the
code reference supplied in the argument, passing the routine the next n values
until all values have been seen. This method returns a L<Data::Object::Hash>
object.

=signature

each(Num $arg1, CodeRef $arg2, Any @args) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..4});

my $result = $data->each_n_values(4, sub { [@_] });

is_deeply [[sort { $a <=> $b } @{$result->[0]}]], [[2,4]];

ok 1 and done_testing;
