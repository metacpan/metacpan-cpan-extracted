use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

set

=usage

  # given {1..8}

  $hash->set(1,10); # 10
  $hash->set(1,12); # 12
  $hash->set(1,0); # 0

=description

The set method returns the value of the element in the hash corresponding to
the key specified by the argument after updating it to the value of the second
argument. This method returns a data type object to be determined after
execution.

=signature

set(Str $arg1, Any $arg2) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Hash';

my $data = Data::Object::Hash->new({1..8});

is_deeply $data->set(1,10), 10;

is_deeply $data->set(1,12), 12;

is_deeply $data->set(1,0), 0;

ok 1 and done_testing;
