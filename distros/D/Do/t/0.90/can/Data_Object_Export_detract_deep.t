use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

detract_deep

=usage

  # given {1,2,3,{4,5,6,[-1, 99, bless({}), sub { 123 }]}};

  my $object = deduce_deep $object;
  my $revert = detract_deep $object; # produces ...

  # {
  #   '1' => 2,
  #   '3' => {
  #     '4' => 5,
  #     '6' => [ -1, 99, bless({}, 'main'), sub { ... } ]
  #     }
  # }

=description

The detract_deep function returns a value of native type. If the data provided
is complex, this function traverses the data converting all nested data type
objects into native values using the objects underlying reference. Note:
Blessed objects are not traversed.

=signature

detract_deep(Any $arg1) : Any

=type

function

=cut

# TESTING

use_ok 'Data::Object::Export';

my $data = 'Data::Object::Export';

can_ok $data, 'detract_deep';

ok 1 and done_testing;
