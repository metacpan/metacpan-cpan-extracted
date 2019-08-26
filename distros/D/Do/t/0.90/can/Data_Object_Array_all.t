use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

all

=usage

  # given [2..5]

  $array->all(fun ($value, @args) {
    $value > 1; # 1, true
  });

  $array->all(fun ($value, @args) {
    $value > 3; # 0; false
  });

=description

The all method returns true if all of the elements in the array meet the
criteria set by the operand and rvalue. This method returns a
L<Data::Object::Number> object.

=signature

all(CodeRef $arg1, Any @args) : NumObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Array';

my $data = Data::Object::Array->new([2..5]);

is_deeply $data->all(sub { $_[0] > 1 }), 1;

is_deeply $data->all(sub { $_[0] > 3 }), 0;

ok 1 and done_testing;
